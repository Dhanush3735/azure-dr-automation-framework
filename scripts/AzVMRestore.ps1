<#
.SYNOPSIS
    Automates the Cross-Region and Cross-Subscription restoration of Azure VMs for Disaster Recovery (DR).

.DESCRIPTION
    This script orchestrates the recovery of Virtual Machines from Azure Recovery Services Vault.
    It supports:
    - Cross-Region Restore (CRR) to secondary paired regions.
    - Cross-Subscription restoration.
    - Idempotency checks (prevents duplicate restore jobs).
    - Dynamic VM naming transformation for DR environments.

.PARAMETER TargetResourceGroupName
    The Resource Group where the restored VM will be placed.

.PARAMETER TargetVMSuffix
    The suffix to append to the restored VM name (e.g., "-DR", "-WestUS"). Default is "-DR".
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $TargetResourceGroupName,
    [Parameter(Mandatory = $true)][string] $StorageAccountName,
    [Parameter(Mandatory = $true)][string] $StorageAccountResourceGroupName,
    [Parameter(Mandatory = $true)][string] $TargetVNetName,           
    [Parameter(Mandatory = $true)][string] $TargetSubnetName,  
    [Parameter(Mandatory = $true)][string] $SourceResourceGroupName,
    [Parameter(Mandatory = $true)][string] $SourceRecoveryServicesVault,
    [Parameter(Mandatory = $false)][string] $VMName,
    [Parameter(Mandatory = $false)][string] $TargetVMSuffix = "-DR", 
    [Parameter(Mandatory = $false)][string] $ArmClientId,
    [Parameter(Mandatory = $false)][string] $ArmClientSecret,
    [Parameter(Mandatory = $false)][string] $ArmTenantId,
    [Parameter(Mandatory = $false)][string] $TargetSubscriptionId,
    [Parameter(Mandatory = $false)][string] $BackupSubscriptionId,
    [Parameter(Mandatory = $false)][bool] $UseSecondaryRegion
)

# ---------------------------------------------------------------------------
# Authentication & Context Setup
# ---------------------------------------------------------------------------
if ($ArmClientId -and $ArmClientSecret -and $ArmTenantId) {
    Write-Verbose "Authenticating using Service Principal..."
    $securePass = ConvertTo-SecureString $ArmClientSecret -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($ArmClientId, $securePass)
    Connect-AzAccount -ServicePrincipal -Credential $cred -Tenant $ArmTenantId -ErrorAction Stop
}

# Define scope of subscriptions to search for resources
$subscriptionsToScan = @()

# Get current context
$currentContext = Get-AzContext
if ($currentContext -and $currentContext.Subscription) {
    $subscriptionsToScan += $currentContext.Subscription.Id
}
# Add backup subscription if provided explicitly
if ($BackupSubscriptionId -and $BackupSubscriptionId -notin $subscriptionsToScan) {
    $subscriptionsToScan += $BackupSubscriptionId
}

# ---------------------------------------------------------------------------
# Vault Discovery
# ---------------------------------------------------------------------------
$recoveryServicesVault = $null
$sourceSubscriptionId = $null

foreach ($subId in $subscriptionsToScan) {
    Write-Output "Scanning for Recovery Services Vault in subscription: $subId"
    Set-AzContext -SubscriptionId $subId -ErrorAction SilentlyContinue
    
    try {
        $recoveryServicesVault = Get-AzRecoveryServicesVault -ResourceGroupName $SourceResourceGroupName -Name $SourceRecoveryServicesVault -ErrorAction Stop
        if ($recoveryServicesVault) {
            $sourceSubscriptionId = ($recoveryServicesVault.Id -split '/')[2]
            Write-Output "Vault '$SourceRecoveryServicesVault' found in subscription: $sourceSubscriptionId"
            break
        }
    }
    catch {
        Write-Verbose "Vault not found in subscription $subId. Continuing scan..."
    }
}

if (-not $recoveryServicesVault) {
    Write-Error "CRITICAL: Recovery Services Vault '$SourceRecoveryServicesVault' not found in the specified scopes."
    exit 1
}

# Set Context to Vault Subscription
Set-AzContext -SubscriptionId $sourceSubscriptionId
Set-AzRecoveryServicesVaultContext -Vault $recoveryServicesVault

# ---------------------------------------------------------------------------
# Network Discovery
# ---------------------------------------------------------------------------
Write-Output "Locating Target VNet: $TargetVNetName in Subnet: $TargetSubnetName"
$targetVNet = $null
$targetVNetResourceGroup = $null

# Determine scope for VNet search (Target Sub + Current Sub)
$vnetScope = @()
if ($TargetSubscriptionId) { $vnetScope += $TargetSubscriptionId }
if ($currentContext.Subscription.Id -notin $vnetScope) { $vnetScope += $currentContext.Subscription.Id }

foreach ($subId in $vnetScope) {
    Set-AzContext -SubscriptionId $subId -ErrorAction SilentlyContinue
    try {
        $targetVNet = Get-AzVirtualNetwork -Name $TargetVNetName -ErrorAction Stop
        if ($targetVNet) {
            $targetVNetResourceGroup = $targetVNet.ResourceGroupName
            Write-Output "Target VNet found in Resource Group: $targetVNetResourceGroup"
            break
        }
    }
    catch {
        Write-Verbose "VNet not found in subscription $subId..."
    }
}

if (-not $targetVNet) {
    Write-Error "CRITICAL: Target VNet '$TargetVNetName' could not be located."
    exit 1
}

# Switch back to Source for Backup operations
Set-AzContext -SubscriptionId $sourceSubscriptionId

# ---------------------------------------------------------------------------
# Restore Logic
# ---------------------------------------------------------------------------
$backupContainers = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -VaultId $recoveryServicesVault.ID

# Filter by VM Name if provided
if ($PSBoundParameters.ContainsKey('VMName') -and $VMName) {
    $backupContainers = $backupContainers | Where-Object { $_.FriendlyName -eq $VMName }
    if (-not $backupContainers) {
        Write-Warning "No backup container found for VM: '$VMName'"
        return
    }
}

foreach ($backupContainer in $backupContainers) {
    $backupItems = Get-AzRecoveryServicesBackupItem -Container $backupContainer -WorkloadType AzureVM -VaultId $recoveryServicesVault.ID
    
    foreach ($backupItem in $backupItems) {
        $originalVMName = $backupContainer.FriendlyName
        
        # --- DR Naming Convention Logic ---
        # Appends the suffix (e.g., -DR ) to ensure no conflict with source
        $restoredVMName = "$originalVMName$TargetVMSuffix"
        Write-Output "Configuration: '$originalVMName' will be restored as -> '$restoredVMName'"

        # --- Recovery Point Selection ---
        $rpParams = @{
            Item = $backupItem
            VaultId = $recoveryServicesVault.ID
        }
        if ($UseSecondaryRegion) { $rpParams['UseSecondaryRegion'] = $true }

        $latestRecoveryPoint = Get-AzRecoveryServicesBackupRecoveryPoint @rpParams | Sort-Object -Property RecoveryPointTime -Descending | Select-Object -First 1
        
        if ($latestRecoveryPoint) {
            
            # --- Idempotency Check (Prevent Conflict) ---
            # Checks for In-Progress or Failed jobs in the last 30 mins to prevent overlapping restores
            Write-Output "Validating job history for $originalVMName..."
            
            $jobParams = @{ VaultId = $recoveryServicesVault.ID; ErrorAction = 'SilentlyContinue' }
            if ($UseSecondaryRegion) { 
                $jobParams['UseSecondaryRegion'] = $true 
                $jobParams['VaultLocation'] = $recoveryServicesVault.Location
            }

            $allJobs = Get-AzRecoveryServicesBackupJob @jobParams
            $blockingJobs = $allJobs | Where-Object { 
                $_.WorkloadName -eq $originalVMName -and 
                ($_.Operation -match "Restore") -and 
                ($_.Status -match "InProgress" -or ($_.StartTime -gt (Get-Date).AddMinutes(-30) -and $_.Status -match "Failed|Cancelled"))
            }

            if ($blockingJobs) {
                Write-Error "ABORTING: Active or recently failed restore job detected for $originalVMName. JobID: $($blockingJobs[0].JobId)"
                continue
            }
            
            # --- Execute Restore ---
            Write-Output "Initiating Restore for $originalVMName..."
            
            $restoreParams = @{
                RecoveryPoint = $latestRecoveryPoint
                TargetResourceGroupName = $TargetResourceGroupName
                StorageAccountName = $StorageAccountName
                StorageAccountResourceGroupName = $StorageAccountResourceGroupName
                TargetVMName = $restoredVMName
                TargetVNetName = $TargetVNetName
                TargetVNetResourceGroup = $targetVNetResourceGroup
                TargetSubnetName = $TargetSubnetName
                VaultId = $recoveryServicesVault.ID
                VaultLocation = $recoveryServicesVault.Location
            }
            
            if ($UseSecondaryRegion) { $restoreParams['RestoreToSecondaryRegion'] = $true }
            if ($TargetSubscriptionId) { $restoreParams['TargetSubscriptionId'] = $TargetSubscriptionId }
            
            $restoreJob = Restore-AzRecoveryServicesBackupItem @restoreParams
            
            # --- Job Monitoring ---
            Write-Output "Restore Job Triggered: $($restoreJob.JobId). Monitoring status..."
            
            $retryCount = 0
            $timeout = 60 # Check for 10 minutes (60 * 10s)
            
            do {
                Start-Sleep -Seconds 10
                $jobCheckParams = @{ VaultId = $recoveryServicesVault.ID }
                if ($UseSecondaryRegion) { 
                    $jobCheckParams['UseSecondaryRegion'] = $true 
                    $jobCheckParams['VaultLocation'] = $recoveryServicesVault.Location
                }
                
                $currentJobStatus = Get-AzRecoveryServicesBackupJob @jobCheckParams | Where-Object { $_.JobId -eq $restoreJob.JobId } | Select-Object -First 1
                $retryCount++
            } while ($currentJobStatus.Status -notin @("Completed", "Failed", "Cancelled") -and $retryCount -lt $timeout)

            if ($currentJobStatus.Status -eq "Completed") {
                Write-Output "SUCCESS: VM '$restoredVMName' is online."
            } else {
                Write-Error "FAILURE: Restore job ended with status: $($currentJobStatus.Status). Details: $($currentJobStatus.Error.Message)"
            }
        } else {
            Write-Warning "No valid Recovery Points found for $originalVMName"
        }
    }
}
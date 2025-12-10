variable "vm_name" {
  type = string
}

variable "vm_count" {
  type = number
}

variable "vm_size" {
  type = string
}

variable "image_os" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_ssh_keys" {
  type = any
}

variable "new_network_interface" {
  type = any
}

variable "os_disk" {
  type = any
}

variable "data_disks" {
  type = any
}

variable "disk_encryption_set_key_vault_id" {
  type = string
}

variable "tags" {
  type = any
}

variable "private_dns_zone_name" {
  type = any
}

variable "virtual_network_id" {
  type = any
}

variable "dns_record_name" {
  type = any
}



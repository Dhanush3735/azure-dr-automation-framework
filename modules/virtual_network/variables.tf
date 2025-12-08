variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "virtual_network_address_spaces" {
  type = list(string)
}

variable "virtual_network_subnet_prefixes" {
  type = list(string)
}

variable "virtual_network_subnet_names" {
  type = list(string)
}

variable "virtual_network_subnet_service_endpoints" {
  type = any
}

variable "virtual_network_subnet_delegation" {
  type = any
}

variable "virtual_network_subnet_enforce_private_link_endpoint_network_policies" {
  type = any
}

variable "virtual_network_peers" {
  type = any
}

variable "natgateway_name" {
  type = string
}

variable "tags" {
  type = any
}

variable "nsg_definitions" {
  type = any
}

variable "subnet_nsg_map" {
  type = any
}

variable "public_ips" {
  type = any
}

variable "public_ip_config" {
  type = any
}

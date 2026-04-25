# =============================================================================
# modules/vsphere_vm/variables.tf — VM Module Inputs
# =============================================================================

variable "vm_name" {
  description = "VM name in vCenter and OS hostname"
  type        = string
}

variable "cpu" {
  description = "Number of vCPUs"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "RAM in MB"
  type        = number
  default     = 4096
}

variable "disk_size_gb" {
  description = "OS disk size in GB — must be >= template disk size"
  type        = number
  default     = 50
}

variable "ip_address" {
  description = "Static IP address"
  type        = string
}

variable "gateway" {
  description = "Default gateway"
  type        = string
  default     = "10.10.0.1"
}

variable "prefix_length" {
  description = "Subnet prefix length (23 = /23 = 255.255.254.0)"
  type        = number
  default     = 23
}

variable "dns_servers" {
  description = "DNS server list"
  type        = list(string)
  default     = ["10.10.1.10", "10.10.0.12"]
}

variable "domain" {
  description = "DNS domain"
  type        = string
  default     = "nnt.com"
}

# vSphere object IDs — passed from root module data sources
variable "resource_pool_id" {
  description = "ESXi host resource pool ID"
  type        = string
}

variable "datastore_id" {
  description = "Target datastore ID"
  type        = string
}

variable "network_id" {
  description = "Port group ID"
  type        = string
}

variable "template_uuid" {
  description = "Template VM UUID"
  type        = string
}

variable "template_guest_id" {
  description = "Guest OS ID from template (e.g. oracleLinux9_64Guest)"
  type        = string
}

variable "folder" {
  description = "vCenter VM folder path"
  type        = string
}

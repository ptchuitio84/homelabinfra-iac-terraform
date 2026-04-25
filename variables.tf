# =============================================================================
# variables.tf — Input Variable Declarations
# =============================================================================
# Declares all inputs. Values live in terraform.tfvars (non-secret) or are
# injected at runtime via -var flags or environment variables (TF_VAR_name).
# No secrets here — vSphere credentials come from Vault in providers.tf.
# =============================================================================

variable "vsphere_server" {
  description = "vCenter FQDN"
  type        = string
}

variable "datacenter" {
  description = "vSphere datacenter name"
  type        = string
}

variable "datastore" {
  description = "Target datastore name"
  type        = string
}

variable "esxi_host" {
  description = "Target ESXi host FQDN — no DRS cluster in use, host specified directly"
  type        = string
}

variable "vm_template" {
  description = "Golden template name — must exist in vCenter"
  type        = string
}

variable "vm_network" {
  description = "Port group name for VM NICs"
  type        = string
}

variable "vm_folder" {
  description = "vCenter VM folder — new VMs land here until promoted"
  type        = string
  default     = "staging"
}

variable "vm_gateway" {
  description = "Default gateway for provisioned VMs"
  type        = string
  default     = "10.10.0.1"
}

variable "vm_dns_servers" {
  description = "DNS servers injected via guest customization"
  type        = list(string)
  default     = ["10.10.1.10", "10.10.0.12"]
}

variable "vm_domain" {
  description = "DNS domain suffix"
  type        = string
  default     = "nnt.com"
}

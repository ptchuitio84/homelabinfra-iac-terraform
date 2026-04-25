# =============================================================================
# providers.tf — Provider Configuration
# =============================================================================
# Two providers:
#   vault   — reads vSphere credentials from HashiCorp Vault at plan time
#   vsphere — uses those credentials to talk to vCenter
#
# WHY VAULT PROVIDER:
#   Terraform never sees the vSphere password in plaintext in any .tf file.
#   At plan/apply time, Terraform authenticates to Vault (using VAULT_TOKEN
#   env var set by Jenkins), reads the secret, and passes it directly to the
#   vSphere provider. No secrets in git, no secrets in tfvars.
#
# EQUIVALENT IN AWS:  aws provider reads from IAM role / AWS Secrets Manager
# EQUIVALENT IN AZURE: azurerm reads from Azure Key Vault / managed identity
# =============================================================================

# Vault provider — address comes from VAULT_ADDR env var (set on tfm001 globally)
# VAULT_TOKEN is injected by Jenkins pipeline from stored credential
provider "vault" {}

# Read vSphere credentials from Vault KV v2
data "vault_kv_secret_v2" "vcenter" {
  mount = "secret"
  name  = "vsphere/vcenter"
}

# vSphere provider — credentials sourced from Vault at runtime
provider "vsphere" {
  user                 = data.vault_kv_secret_v2.vcenter.data["username"]
  password             = data.vault_kv_secret_v2.vcenter.data["password"]
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

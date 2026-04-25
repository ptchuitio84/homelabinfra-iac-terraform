# =============================================================================
# backend.tf — Terraform State Backend
# =============================================================================
# Remote state stored in Minio (S3-compatible) at hmvlapmin001.
# All plan/apply operations read and write state here — never local.
#
# WHY S3 BACKEND ON MINIO:
#   State is the source of truth for what Terraform manages. Storing it
#   remotely means any machine (Jenkins, workstation, tfm001) sees the
#   same state. Local state gets out of sync the moment two people run
#   terraform — or you rebuild the machine.
#
# EQUIVALENT IN AWS:  s3://bucket/key  (same backend, real AWS S3)
# EQUIVALENT IN AZURE: azurerm backend → Azure Blob Storage
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.8"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket   = "terraform-state"
    key      = "vsphere/terraform.tfstate"
    endpoint = "http://10.10.0.47:9000"

    # Minio credentials — not production AWS keys, safe to commit
    access_key = "minio"
    secret_key = "M1n10nnt#2026"

    # Required by the S3 backend protocol — value is ignored by Minio
    region = "us-east-1"

    # Minio-specific: use path-style URLs and skip AWS-specific validation
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}

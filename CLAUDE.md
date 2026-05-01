# homelabinfra-iac-terraform

Proof-of-concept Terraform repo. Used to prove the Vault-vCenter-Minio cycle end-to-end.
NOT used for production VM lifecycle management — that is homelabinfra-iac-vms.

## Purpose
Single VM (hmvlaptst001) was provisioned and destroyed to validate:
- Vault provider reading vSphere credentials at runtime
- vSphere provider cloning from EFI template
- Minio S3 backend storing state

## Pipeline — nnt-jkn-terraform-apply
- Agent: tfm001 (hmvlaptfm001, 10.10.0.48) — Java 21 required
- Parameters: TF_BINARY (tofu/terraform), TF_ACTION (plan/apply/destroy)
- VAULT_TOKEN injected from Jenkins credential `nnt-vault-root-token`

## Infrastructure
- State: Minio at `http://10.10.0.47:9000`, bucket `terraform-state`, key `vsphere/terraform.tfstate`
- Vault: `http://10.10.0.44:8200` — vSphere credentials at `secret/vsphere/vcenter`

## Key Gotchas
- EFI firmware: always set `firmware = "efi"` + `efi_secure_boot_enabled = true` — template is EFI. BIOS clone of EFI template = PXE boot every time.
- `disk_size_gb` must be >= template disk size (60GB) or plan fails
- Minio backend requires `force_path_style = true` and all skip_* flags — standard S3 validation doesn't apply to Minio

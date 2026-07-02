# homelabinfra-iac-terraform

Declarative vSphere infrastructure provisioning using OpenTofu and Terraform. This repo owns **what exists** in the homelab — VM creation, configuration, and teardown are all expressed as code, tracked in state, and executed through a Jenkins CI/CD pipeline.

Ansible (`homelabinfra-iac-ansible`) owns what runs **on** the infrastructure after it exists. These two repos are intentionally separate: different tools, different lifecycles, different failure domains.

---

## Architecture

```
Git push (this repo)
    ↓
Jenkins pipeline — lab-jkn-terraform-apply
    ↓ runs on tf-runner-01 (dedicated Terraform execution node)
    ↓
tofu init → tofu plan → tofu apply
    │                        │
    ▼                        ▼
Vault (vSphere          vCenter API
 credentials)           (provisions VM)
    │                        │
    ▼                        ▼
Minio S3 backend        VM is live
(terraform.tfstate)
```

**Execution node:** `tf-runner-01` (192.168.0.48) — dedicated OL9 VM running as Jenkins agent `tfm001`. All Terraform operations run here, isolated from the Ansible control node (`ans001`).

**State backend:** Minio at `minio-01` (192.168.0.47) — S3-compatible object storage. State lives in the `terraform-state` bucket under `vsphere/terraform.tfstate`. Every plan and apply reads and writes here — no local state, ever.

**Credentials:** HashiCorp Vault at `vault-01` (192.168.0.44). The vSphere provider reads `secret/vsphere/vcenter` at plan time via the Vault provider. No credentials in this repo, no credentials in `terraform.tfvars`.

---

## Prerequisites

| Requirement | Location | Notes |
|---|---|---|
| OpenTofu ≥ 1.9 | `tf-runner-01` | Primary binary — `tofu` |
| Terraform ≥ 1.10 | `tf-runner-01` | Side-by-side install — `terraform` |
| Vault unsealed | `vault-01:8200` | Must be unsealed before any plan/apply |
| Vault secret | `secret/vsphere/vcenter` | Keys: `username`, `password` |
| Minio running | `minio-01:9000` | Bucket `terraform-state` must exist |
| Jenkins agent | `tfm001` label | `tf-runner-01` registered in Jenkins |
| Jenkins credential | `vault-root-token` | Secret text — Vault root token |
| vCenter template | `ol9-golden-YYYYMMDD` | Golden OL9.7 image in vCenter |

---

## Repository Structure

```
homelabinfra-iac-terraform/
├── backend.tf          # Remote state → Minio S3 backend + provider version pins
├── providers.tf        # Vault provider (credential source) + vSphere provider
├── variables.tf        # Input variable declarations
├── terraform.tfvars    # Non-secret values (datacenter, datastore, template, etc.)
├── main.tf             # Infrastructure declarations — VMs defined here
├── outputs.tf          # Values surfaced after apply (IPs, VM IDs)
└── modules/
    └── vsphere_vm/     # Reusable VM module
        ├── main.tf     # vsphere_virtual_machine resource with guest customization
        ├── variables.tf
        └── outputs.tf
```

---

## Running Locally (on tf-runner-01)

```bash
# Set Vault token — Jenkins injects this automatically; set manually for local runs
export VAULT_ADDR=http://192.168.0.44:8200
export VAULT_TOKEN=<vault-root-token>

cd /opt/homelabinfra-iac-terraform

# Initialize — downloads providers, connects to Minio backend
tofu init

# Plan — shows what will be created/changed/destroyed. Nothing is applied.
tofu plan

# Apply — executes the plan. Prompts for confirmation.
tofu apply

# Destroy — tears down everything tracked in state. Prompts for confirmation.
tofu destroy
```

---

## Jenkins Pipeline

**Pipeline:** `lab-jkn-terraform-apply`
**Agent:** `tfm001`
**Groovy:** `jenkins/infra/lab-jkn-terraform-apply.groovy` (in `homelabinfra-iac-ansible` repo)

Parameters:

| Parameter | Options | Description |
|---|---|---|
| `TF_BINARY` | `tofu`, `terraform` | Which binary to execute |
| `TF_ACTION` | `plan`, `apply`, `destroy` | Operation to run |

Run `plan` first to validate before every `apply`. The plan output is saved to `tfplan` and applied without re-prompting in the apply stage — what you saw in plan is exactly what apply executes.

---

## Adding a New VM

1. Add a module block in `main.tf`:

```hcl
module "lab-vm-xxx-01" {
  source = "./modules/vsphere_vm"

  vm_name      = "lab-vm-xxx-01"
  cpu          = 2
  memory_mb    = 4096
  disk_size_gb = 50
  ip_address   = "192.168.0.XX"

  resource_pool_id  = data.vsphere_host.esxi.resource_pool_id
  datastore_id      = data.vsphere_datastore.ds.id
  network_id        = data.vsphere_network.vm_network.id
  template_uuid     = data.vsphere_virtual_machine.template.id
  template_guest_id = data.vsphere_virtual_machine.template.guest_id
  folder            = var.vm_folder
}
```

2. Add a corresponding output in `outputs.tf` if the IP is needed downstream.
3. Commit, push, run `plan` in Jenkins, review, run `apply`.
4. After the VM is live, trigger the Ansible `lab-jkn-provision-vm`-equivalent playbook to configure the OS.

---

## State Management

State is the source of truth for what Terraform manages. A few operational rules:

- **Never delete the state file manually.** If a VM is removed from vCenter outside of Terraform, use `tofu state rm <resource>` to remove it from state before the next plan.
- **Never run `tofu apply` from two places simultaneously.** Minio does not support state locking — concurrent applies will corrupt state. Jenkins serializes this automatically; avoid running locally while a Jenkins job is active.
- **State contains no secrets.** vSphere credentials are fetched from Vault at runtime and never written to the state file.

---

## Design Decisions

**Why a dedicated execution VM instead of running from ans001?**
Separate failure domain. A runaway Terraform apply that consumes CPU/memory doesn't degrade the Ansible control plane. Separate VM also allows separate Vault policies, separate audit logs, and a clean separation of team ownership in a multi-team environment.

**Why OpenTofu as the primary binary?**
HashiCorp changed Terraform's license to BSL in 2023. OpenTofu is the Linux Foundation-backed open-source fork. Syntax is identical — the same `.tf` files run with either binary. Both are installed here for learning and comparison.

**Why Vault for vSphere credentials instead of tfvars?**
`terraform.tfvars` is committed to git. Credentials in tfvars means credentials in git history — permanently, even after rotation. Vault provides a single credential store with audit logging, rotation support, and policy-based access control. In AWS this would be IAM roles + Secrets Manager; in Azure it would be managed identity + Key Vault.

**Why Minio for state instead of local files?**
Local state is a single point of failure — tied to one machine, lost if the machine is rebuilt. Remote state means any authorized machine can run Terraform against the same infrastructure without conflicts or drift.

---

## First-Time Setup

**1. Store vSphere credentials in Vault (one-time, on vault-01):**
```bash
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=<root-token>
vault kv put secret/vsphere/vcenter username=administrator@vsphere.local password=<vcenter-password>
```

**2. Verify the Minio `terraform-state` bucket exists (on minio-01):**
```bash
mc alias set local http://localhost:9000 <access-key> <secret-key>
mc ls local/terraform-state
# If missing: mc mb local/terraform-state
```

**3. Confirm Jenkins credential `vault-root-token` is set:**
Jenkins → Manage Jenkins → Credentials → Global → `vault-root-token` (Secret Text, Vault root token).

**4. Initialize on tf-runner-01:**
```bash
export VAULT_ADDR=http://192.168.0.44:8200
export VAULT_TOKEN=<vault-root-token>
cd /opt/homelabinfra-iac-terraform
tofu init
tofu plan  # Verify credentials and state backend connect correctly
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Error: Failed to query available provider packages` | Minio unreachable or bucket missing | Verify minio-01 is up, `terraform-state` bucket exists |
| `Error: Permission denied` on Vault lookup | Vault sealed or VAULT_TOKEN wrong | `vault status` on vault-01 — unseal if needed |
| `Error: Could not connect to vCenter` | vCenter unreachable or credentials wrong | Verify vCenter is up, check `secret/vsphere/vcenter` in Vault |
| `Plan shows unexpected changes` | VM drifted from Terraform state (manual vCenter change) | Review diff carefully — `tofu state show <resource>` to inspect current state |
| `State file locked` | A previous apply didn't finish cleanly | Minio has no state locking — check if another apply is running; if not, safe to proceed |
| `EFI boot failure after clone` | Template firmware mismatch | VM module must set `firmware = "efi"` and `efi_secure_boot_enabled = true` — matches `ol9-golden-YYYYMMDD` template |

---

## Homelab Infrastructure Reference

| VM | IP | Role |
|---|---|---|
| vcenter-01 | — | vCenter (provisioning target) |
| tf-runner-01 | 192.168.0.48 | This execution node |
| minio-01 | 192.168.0.47 | Minio (state backend) |
| vault-01 | 192.168.0.44 | HashiCorp Vault (credential source) |
| jenkins-01 | 192.168.1.41 | Jenkins (pipeline orchestrator) |

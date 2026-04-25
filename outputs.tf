# =============================================================================
# outputs.tf — Root Module Outputs
# =============================================================================
# Values printed after apply and stored in state.
# Useful for piping into other tools (Ansible inventory, DNS scripts, etc.)
# =============================================================================

output "hmvlaptst001_ip" {
  description = "IP address of test VM"
  value       = module.hmvlaptst001.ip_address
}

output "hmvlaptst001_id" {
  description = "vSphere VM ID of test VM"
  value       = module.hmvlaptst001.vm_id
}

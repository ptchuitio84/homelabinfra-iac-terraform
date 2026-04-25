# =============================================================================
# modules/vsphere_vm/outputs.tf — VM Module Outputs
# =============================================================================

output "vm_id" {
  description = "vSphere VM managed object ID"
  value       = vsphere_virtual_machine.this.id
}

output "ip_address" {
  description = "VM IP address (from guest customization)"
  value       = var.ip_address
}

output "vm_name" {
  description = "VM name in vCenter"
  value       = vsphere_virtual_machine.this.name
}

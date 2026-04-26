# =============================================================================
# modules/vsphere_vm/main.tf — Reusable vSphere VM Module
# =============================================================================
# Clones a VM from the golden template, applies VMware Guest Customization
# to set hostname and static IP, and powers it on.
#
# This is the Terraform equivalent of roles/provision_vm in Ansible.
# The difference: Terraform tracks this VM in state — it knows the VM exists,
# can update it, and can destroy it cleanly. Ansible's provision_vm is
# fire-and-forget; it doesn't track what it created.
#
# EQUIVALENT IN AWS:  aws_instance resource
# EQUIVALENT IN AZURE: azurerm_linux_virtual_machine resource
# =============================================================================

resource "vsphere_virtual_machine" "this" {
  name             = var.vm_name
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  folder           = var.folder

  num_cpus  = var.cpu
  memory    = var.memory_mb
  guest_id  = var.template_guest_id
  firmware              = "efi"
  efi_secure_boot_enabled = true

  # VMware paravirtual SCSI — matches OL9 golden template
  scsi_type = "pvscsi"

  network_interface {
    network_id   = var.network_id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = var.disk_size_gb
    thin_provisioned = true
  }

  clone {
    template_uuid = var.template_uuid

    # VMware Guest Customization — sets hostname and static IP at first boot
    # Same mechanism Ansible's provision_vm role uses
    customize {
      linux_options {
        host_name = var.vm_name
        domain    = var.domain
      }

      network_interface {
        ipv4_address = var.ip_address
        ipv4_netmask = var.prefix_length
      }

      ipv4_gateway    = var.gateway
      dns_server_list = var.dns_servers
    }
  }
}

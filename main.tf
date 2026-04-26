# =============================================================================
# main.tf — Infrastructure Declarations
# =============================================================================
# Declares what exists. Terraform compares this against the state file and
# the real vCenter, then builds a plan to make reality match this file.
#
# CURRENT WORKLOAD: One test VM (hmvlaptst001) to prove the full cycle:
#   tofu apply  → VM appears in vCenter, state written to Minio
#   tofu destroy → VM removed, state updated in Minio
# =============================================================================

# ---------------------------------------------------------------------------
# DATA SOURCES — Look up existing vSphere objects by name
# These don't create anything. They resolve names to IDs that resources need.
# Equivalent to aws_ami data source or azurerm_resource_group data source.
# ---------------------------------------------------------------------------

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "ds" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "esxi" {
  name          = var.esxi_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "vm_network" {
  name          = var.vm_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

# ---------------------------------------------------------------------------
# VMs
# ---------------------------------------------------------------------------

module "hmvlaptst001" {
  source = "./modules/vsphere_vm"

  vm_name      = "hmvlaptst001"
  cpu          = 2
  memory_mb    = 4096
  disk_size_gb = 60
  ip_address   = "10.10.0.49"

  resource_pool_id  = data.vsphere_host.esxi.resource_pool_id
  datastore_id      = data.vsphere_datastore.ds.id
  network_id        = data.vsphere_network.vm_network.id
  template_uuid     = data.vsphere_virtual_machine.template.id
  template_guest_id = data.vsphere_virtual_machine.template.guest_id
  folder            = var.vm_folder
}

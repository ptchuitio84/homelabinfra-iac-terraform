# =============================================================================
# terraform.tfvars — Non-Secret Variable Values
# =============================================================================
# All values here are non-sensitive infrastructure facts.
# vSphere credentials are NOT here — they come from Vault at runtime.
# =============================================================================

vsphere_server = "hmvlapvc001.nnt.com"
datacenter     = "NNTDC"
datastore      = "LUNPLV163001"
esxi_host      = "hsplv021.nnt.com"
vm_template    = "PLTMPOL904242026"
vm_network     = "VLAN010_CORE_UP010"
vm_folder      = "staging"

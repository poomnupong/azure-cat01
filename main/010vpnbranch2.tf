// VNET Branch 1 - connect to vnethub1 with VPN to simmulate BGP-connected branch office

module "vpnbranch2" {
  # depends_on          = [module.vnethub1]
  source              = "../modules/vnethubgeneric-mod/"
  REGION              = var.REGION
  RESOURCENAME        = "${var.PREFIX}-${var.BRANCH}-vpnbranch2-${var.REGION}"
  ISDEPLOYGWEXR       = false
  ISDEPLOYROUTESERVER = false
  GWVPNASNUMBER       = 65012
  ADDRESS_SPACE       = "10.1.12.0/24"
  TAGS = {
    "prefix" = var.PREFIX
    "branch" = var.BRANCH
  }
}

resource "azurerm_virtual_network_gateway_connection" "vpnbranch2_to_vnethub1" {
  depends_on = [
    module.vpnbranch2,
    module.vnethub1
  ]
  name                            = "${var.PREFIX}-${var.BRANCH}-vpnbranch2-to-vnethub1-conn"
  location                        = module.vpnbranch2.gwvpn.location
  resource_group_name             = module.vpnbranch2.vnet1.resource_group_name
  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = try(module.vpnbranch2.gwvpn.id)
  peer_virtual_network_gateway_id = try(module.vnethub1.gwvpn.id)
  shared_key                      = "Azure@1234567890"
  enable_bgp                      = true
  # routing_weight                  = 0
}

resource "azurerm_virtual_network_gateway_connection" "vnethub1_to_vpnbranch2" {
  depends_on = [
    module.vpnbranch2,
    module.vnethub1
  ]
  name                            = "${var.PREFIX}-${var.BRANCH}-vnethub1-to-vpnbranch2-conn"
  location                        = module.vnethub1.gwvpn.location
  resource_group_name             = module.vnethub1.vnet1.resource_group_name
  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = try(module.vnethub1.gwvpn.id)
  peer_virtual_network_gateway_id = try(module.vpnbranch2.gwvpn.id)
  shared_key                      = "Azure@1234567890"
  enable_bgp                      = true
  # routing_weight                  = 0
}


// === a test VM ===

module "vpnbranch2-vm1" {
  depends_on      = [module.vpnbranch2]
  source          = "../modules/vmlinuxgeneric-mod/"
  REGION          = var.REGION
  SUBNETID        = "${module.vpnbranch2.vnet1.id}/subnets/general1-snet"
  RGNAME          = module.vpnbranch2.vnet1.resource_group_name
  VMNAME          = "vpnbranch2-test1"
  VMSKU           = "Standard_B2ats_v2"
  VMDATADISK1SIZE = 0
}

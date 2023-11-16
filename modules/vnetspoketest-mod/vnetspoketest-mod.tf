// Module for general spoke vnet
// - comes with a resource group
// - accept only /24 address space for now


// === VARIABLES ===

variable "REGION" {
  type        = string
  description = "Azure region to deploy to"
  default     = "westus3"
}

variable "RESOURCENAME" {
  type        = string
  description = "name of the resource describing its purpose"
  default     = "hubZ"
}

# accept only one /24 address space for now
variable "ADDRESS_SPACE" {
  type        = string
  description = "/24 address space for the vnet"
  # default     = "10.255.255.0/24"
}

variable "HUB_VNET_ID" {
  type        = string
  description = "hub vnet id"
}

variable "HUB_VNET_NAME" {
  type        = string
  description = "hub vnet name"
}

variable "HUB_VNET_RG" {
  type        = string
  description = "hub vnet resource group"
}

variable "ISDEPLOYVMTEST" {
  type        = bool
  description = "deploy a test VM"
  default     = true
}

variable "ISDEPLOYVMTESTPUBIP" {
  type        = bool
  description = "deploy a public IP to the VM; need to re-deploy VM manually to change"
  default     = false
}

variable "TAGS" {
  type        = map(string)
  description = "tags to be applied to all resources"
  default     = {}
}


// === RESOURCE GROUP ===

resource "azurerm_resource_group" "rg1" {
  name     = "${var.RESOURCENAME}-rg"
  location = var.REGION
  tags     = var.TAGS
}


// === RESOURCE: prepare subnet map ===

module "subnet_addrs" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = var.ADDRESS_SPACE
  networks = [
    {
      name     = "general1-snet"
      new_bits = 3
    },
    {
      name     = "general2-snet"
      new_bits = 3
    }
  ]
}


// === RESOURCE: vnet and subnets ===

resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.RESOURCENAME}-vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [var.ADDRESS_SPACE]

  dynamic "subnet" {
    for_each = module.subnet_addrs.networks
    content {
      name           = subnet.value.name
      address_prefix = subnet.value.cidr_block
    }
  }
}

module "nsgsubnet" {
  depends_on        = [azurerm_virtual_network.vnet1]
  for_each          = { for i in azurerm_virtual_network.vnet1.subnet : i.name => i if !(i.name == "GatewaySubnet" || i.name == "AzureFirewallSubnet" || i.name == "RouteServerSubnet") }
  source            = "../nsgsubnet-mod/"
  VNET              = azurerm_virtual_network.vnet1
  SUBNET            = each.value
  LOCATION          = azurerm_virtual_network.vnet1.location
  RESOURCEGROUPNAME = azurerm_virtual_network.vnet1.resource_group_name
}


// === RESOURCE: peer vnet1 to the hub vnet ===

resource "azurerm_virtual_network_peering" "spoke_to_hub-peer" {
  name                         = "${azurerm_virtual_network.vnet1.name}-to-${var.HUB_VNET_NAME}-peer"
  resource_group_name          = azurerm_resource_group.rg1.name
  virtual_network_name         = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id    = var.HUB_VNET_ID
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true // to change to true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke-peer" {
  name                         = "${var.HUB_VNET_NAME}-to-${azurerm_virtual_network.vnet1.name}-peer"
  resource_group_name          = var.HUB_VNET_RG
  virtual_network_name         = var.HUB_VNET_NAME
  remote_virtual_network_id    = azurerm_virtual_network.vnet1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true // to change to true
  use_remote_gateways          = false
}


// === RESOURCE: a test VM ===

module "vmtest1" {
  count           = try(var.ISDEPLOYVMTEST ? 1 : 0)
  source          = "../vmlinuxgeneric-mod/"
  REGION          = var.REGION
  SUBNETID        = "${azurerm_virtual_network.vnet1.id}/subnets/general1-snet"
  RGNAME          = azurerm_resource_group.rg1.name
  VMNAME          = "${var.RESOURCENAME}-test1"
  VMSKU           = "Standard_B2ats_v2"
  VMDATADISK1SIZE = 0
  ISDEPLOYPUBIP   = var.ISDEPLOYVMTESTPUBIP
}


// === OUTPUT ===

output "vnet1" {
  value = azurerm_virtual_network.vnet1
}

output "rg" {
  value = azurerm_resource_group.rg1
}

output "vm1" {
  value = module.vmtest1.*.vm1
}

// Module for hub vnet
// - comes with a resource group
// - accept only /24 address space due how cidr function works
// - deploy VPN gateway by default because we need a gateway to for proper peering with remote gateway
// - other conditionally deployable resources, check ISDEPLOY__


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
  default     = "10.255.255.0/24"
}

variable "ISDEPLOYGWEXR" {
  type        = bool
  description = "if set to true, deploy ExpressRoute gateway"
  default     = false
}

variable "GWVPNASNUMBER" {
  type        = number
  description = "BGP AS number"
  default     = 65001
}

variable "ISDEPLOYROUTESERVER" {
  type        = bool
  description = "if set to true, deploy route server"
  default     = false

}

variable "ISDEPLOYAZFW" {
  type        = bool
  description = "if set to true, deploy Azure Firewall"
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
      new_bits = 4
    },
    {
      name     = "nvamgmt-snet"
      new_bits = 4
    },
    {
      name     = "nvainside-snet"
      new_bits = 4
    },
    {
      name     = "nvaoutside-snet"
      new_bits = 4
    },
    {
      name     = "AzureFirewallSubnet"
      new_bits = 2
    },
    {
      name     = "RouteServerSubnet"
      new_bits = 3
    },
    {
      name     = "GatewaySubnet"
      new_bits = 3
    }
  ]
}


// === RESOURCE: VNET and subnets ===

resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.RESOURCENAME}-vnet"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  address_space       = [module.subnet_addrs.base_cidr_block]

  dynamic "subnet" {
    for_each = module.subnet_addrs.networks
    content {
      name           = subnet.value.name
      address_prefix = subnet.value.cidr_block
    }
  }
}


// === RESOURCE: attach NSGs to all non-system subnets ===

module "nsgsubnet" {
  depends_on        = [azurerm_virtual_network.vnet1]
  for_each          = { for i in azurerm_virtual_network.vnet1.subnet : i.name => i if !(i.name == "GatewaySubnet" || i.name == "AzureFirewallSubnet" || i.name == "RouteServerSubnet") }
  source            = "../nsgsubnet-mod/"
  VNET              = azurerm_virtual_network.vnet1
  SUBNET            = each.value
  LOCATION          = azurerm_virtual_network.vnet1.location
  RESOURCEGROUPNAME = azurerm_virtual_network.vnet1.resource_group_name
}

// === RESOURCE: Virtual Network Gateways, VPN ===

resource "azurerm_public_ip" "vnet1_gwvpn-pip1" {
  name                = "${var.RESOURCENAME}-gwvpn-pip1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "vnet1_gwvpn-pip2" {
  name                = "${var.RESOURCENAME}-gwvpn-pip2"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "vnet1_gwvpn-pip3" {
  name                = "${var.RESOURCENAME}-gwvpn-pip3"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "vnet1_gwvpn" {
  // wait until nsgvnetfor-mod is deployed
  # depends_on          = [module.nsgvnetfor]
  depends_on          = [module.nsgsubnet]
  name                = "${var.RESOURCENAME}-gwvpn"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  generation          = "Generation1"
  active_active       = true // need active-active with route server
  enable_bgp          = true

  ip_configuration {
    name                 = "gwvpn-ipconfig1"
    subnet_id            = "${azurerm_virtual_network.vnet1.id}/subnets/GatewaySubnet"
    public_ip_address_id = azurerm_public_ip.vnet1_gwvpn-pip1.id
  }

  ip_configuration {
    name                 = "gwvpn-ipconfig2"
    subnet_id            = "${azurerm_virtual_network.vnet1.id}/subnets/GatewaySubnet"
    public_ip_address_id = azurerm_public_ip.vnet1_gwvpn-pip2.id
  }

  ip_configuration {
    name                 = "gwvpn-ipconfig3"
    subnet_id            = "${azurerm_virtual_network.vnet1.id}/subnets/GatewaySubnet"
    public_ip_address_id = azurerm_public_ip.vnet1_gwvpn-pip3.id
  }

  bgp_settings {
    asn = var.GWVPNASNUMBER
    # bgp_peering_address = ""
  }

  vpn_client_configuration {
    address_space = ["10.254.254.0/24"]
  }

}


// === RESOURCE: Virtual Network Gateways, ExpressRoute ===

resource "azurerm_public_ip" "gwexr-pip1" {
  count               = var.ISDEPLOYGWEXR ? 1 : 0
  name                = "${var.RESOURCENAME}-gwexr-pip1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "gwexr" {
  depends_on = [module.nsgsubnet]
  count      = try(var.ISDEPLOYGWEXR ? 1 : 0, 0)
  name       = "${var.RESOURCENAME}-gwexr"
  # depends_on = [
  #   azurerm_virtual_network.vnet1
  # ]
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  type                = "ExpressRoute"
  sku                 = "Standard"

  ip_configuration {
    name                 = "gwexr-ipconfig1"
    subnet_id            = "${azurerm_virtual_network.vnet1.id}/subnets/GatewaySubnet"
    public_ip_address_id = azurerm_public_ip.gwexr-pip1[0].id
  }
}


// === RESOURCE: Route Server ===

resource "azurerm_public_ip" "ars1-pip1" {
  count               = try(var.ISDEPLOYROUTESERVER ? 1 : 0, 0)
  name                = "${var.RESOURCENAME}-ars-pip1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "ars1" {
  depends_on                       = [module.nsgsubnet]
  count                            = try(var.ISDEPLOYROUTESERVER ? 1 : 0, 0)
  name                             = "${var.RESOURCENAME}-ars"
  resource_group_name              = azurerm_resource_group.rg1.name
  location                         = azurerm_resource_group.rg1.location
  sku                              = "Standard"
  public_ip_address_id             = try(azurerm_public_ip.ars1-pip1[0].id)
  subnet_id                        = "${azurerm_virtual_network.vnet1.id}/subnets/RouteServerSubnet"
  branch_to_branch_traffic_enabled = true
  # tags = {
  #   "tag1" = "value1"
  # }
}


// === RESOURCE: Azure Firewall ===

resource "azurerm_public_ip" "azfw1-pip1" {
  count               = try(var.ISDEPLOYAZFW ? 1 : 0, 0)
  name                = "${var.RESOURCENAME}-azfw-pip1"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "azfw1" {
  depends_on          = [module.nsgsubnet, azurerm_public_ip.azfw1-pip1]
  count               = try(var.ISDEPLOYAZFW ? 1 : 0, 0)
  name                = "${var.RESOURCENAME}-azfw"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "ipconfig1"
    subnet_id            = "${azurerm_virtual_network.vnet1.id}/subnets/AzureFirewallSubnet"
    public_ip_address_id = try(azurerm_public_ip.azfw1-pip1[0].id)
  }

  # tags = {
  #   Environment = "Production"
  # }
}



// === OUTPUTs ====

output "vnet1" {
  value = azurerm_virtual_network.vnet1
}

output "rg" {
  value = azurerm_resource_group.rg1
}

output "gwvpn" {
  value = azurerm_virtual_network_gateway.vnet1_gwvpn
}

output "gwexr" {
  value = azurerm_virtual_network_gateway.gwexr
}

output "ars" {
  value = azurerm_route_server.ars1
}

// module for creating NSGs and attaching them to all non-system subnets

variable "vnet" {
  description = "The azurerm_virtual_network object"
  # type        = any
}

locals {
  subnets = [for s in var.vnet.subnet : s if !(s.name == "GatewaySubnet" || s.name == "AzureFirewallSubnet" || s.name == "RouteServerSubnet")]
}

resource "azurerm_network_security_group" "nsg" {
  count               = length(local.subnets)
  name                = "${var.vnet.name}-${local.subnets[count.index].name}-nsg"
  location            = var.vnet.location
  resource_group_name = var.vnet.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "association" {
  depends_on                = [azurerm_network_security_group.nsg]
  count                     = length(local.subnets)
  subnet_id                 = local.subnets[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg[count.index].id
}

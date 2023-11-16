// module for creating NSGs and attach it to a subnet


variable "VNET" {
  description = "The azurerm_virtual_network object"
  # type        = any
}

variable "SUBNET" {
  description = "The azurerm_subnet object"
  # type        = any
}

variable "LOCATION" {
  description = "The Azure Region in which all resources in this example should be created."
}

variable "RESOURCEGROUPNAME" {
  description = "The name of the resource group in which all resources in this example should be created."
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.VNET.name}-${var.SUBNET.name}-nsg"
  location            = var.LOCATION
  resource_group_name = var.RESOURCEGROUPNAME
}

resource "azurerm_subnet_network_security_group_association" "association" {
  depends_on                = [azurerm_network_security_group.nsg]
  subnet_id                 = var.SUBNET.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

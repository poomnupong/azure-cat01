// module for creating route server


variable "subnet" {
  description = "The azurerm_subnet object"
  # type        = any
}

variable "LOCATION" {
  description = "The Azure Region in which all resources in this example should be created."
}

variable "RESOURCEGROUPNAME" {
  description = "The name of the resource group in which all resources in this example should be created."
}

// === RESOURCE: route server ===


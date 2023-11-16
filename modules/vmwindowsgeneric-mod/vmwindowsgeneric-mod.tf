// Module for generic Azure Linux VM
// - with 1 NIC
// - hardcoded to Ubuntu 22.04 LTS


// === variables ===

variable "REGION" {
  type        = string
  description = "Azure region to deploy to"
  default     = "westus3"
}

variable "SUBNETID" {
  type        = string
  description = "value of subnet id"
}

variable "RGNAME" {
  type        = string
  description = "value of resource group name"
}

variable "VMNAME" {
  type        = string
  description = "value of vm name"
}

variable "VMSKU" {
  type        = string
  description = "value of vm sku"
}

variable "VMDATADISK1SIZE" {
  type        = number
  description = "value of vm data disk 1 size"
  default     = 0
}

variable "ISDEPLOYPUBIP" {
  type        = bool
  description = "deploy a public IP"
  default     = false
}

variable "ADMINUSERNAME" {
  type        = string
  description = "value of admin username"
  default     = "azureuser"
}

variable "ADMINPASSWORD" {
  type        = string
  description = "value of admin password"
  default     = "Azure123456$"
  sensitive   = true
}


// === RESOURCE: VM ===

resource "azurerm_public_ip" "vm1_pubip1" {
  count               = var.ISDEPLOYPUBIP ? 1 : 0
  name                = "${var.VMNAME}-vm-pubip1"
  location            = var.REGION
  resource_group_name = var.RGNAME
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "vm1_nic1" {
  name                = "${var.VMNAME}-vm-nic1"
  location            = var.REGION
  resource_group_name = var.RGNAME

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.SUBNETID
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.ISDEPLOYPUBIP ? azurerm_public_ip.vm1_pubip1[0].id : null
  }
}

resource "azurerm_network_security_group" "vm1_nic1_nsg" {
  name                = "${azurerm_network_interface.vm1_nic1.name}-nsg"
  location            = var.REGION
  resource_group_name = var.RGNAME

  # security_rule {
  #   name = "allow-rdp"
  #   priority = 1001
  #   direction = "Inbound"
  #   access = "Allow"
  #   protocol = "Tcp"
  #   source_port_range = "*"
  #   destination_port_range = "3389"
  #   source_address_prefix = "*"
  #   destination_address_prefix = "*"
  # }

}

resource "azurerm_network_interface_security_group_association" "vm1_nsg1_association" {
  network_interface_id      = azurerm_network_interface.vm1_nic1.id
  network_security_group_id = azurerm_network_security_group.vm1_nic1_nsg.id
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name = "${var.VMNAME}-vm"
  # depends_on = [
  #   azurerm_network_interface.vm1_nic1,
  #   azurerm_network_security_group.vm1_nsg
  # ]
  location              = var.REGION
  resource_group_name   = var.RGNAME
  network_interface_ids = [azurerm_network_interface.vm1_nic1.id]
  size                  = var.VMSKU
  priority              = "Spot"
  eviction_policy       = "Deallocate"
  max_bid_price         = -1
  admin_username        = var.ADMINUSERNAME
  admin_password        = var.ADMINPASSWORD

  os_disk {
    name                 = "${var.VMNAME}-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {}

}

resource "azurerm_managed_disk" "datadisk1" {
  count                = var.VMDATADISK1SIZE > 0 ? 1 : 0
  name                 = "${azurerm_windows_virtual_machine.vm1.name}-datadisk1"
  location             = var.REGION
  resource_group_name  = var.RGNAME
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.VMDATADISK1SIZE
}

resource "azurerm_virtual_machine_data_disk_attachment" "datadisk1-attachment" {
  count              = var.VMDATADISK1SIZE > 0 ? 1 : 0
  managed_disk_id    = try(azurerm_managed_disk.datadisk1[0].id)
  virtual_machine_id = azurerm_windows_virtual_machine.vm1.id
  lun                = "0"
  caching            = "ReadWrite"
}

output "vm1" {
  value = azurerm_windows_virtual_machine.vm1
}

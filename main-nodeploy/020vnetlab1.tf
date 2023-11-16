// VNET and lab components
// peer with the hub
// - hyper-v and kvm hosts with nested virtualization

module "vnetlab1" {
  depends_on          = [module.vnethub1]
  source              = "../modules/vnetspoketest-mod/"
  REGION              = var.REGION
  RESOURCENAME        = "${var.PREFIX}-${var.BRANCH}-lab1-${var.REGION}"
  HUB_VNET_ID         = module.vnethub1.vnet1.id
  HUB_VNET_NAME       = module.vnethub1.vnet1.name
  HUB_VNET_RG         = module.vnethub1.vnet1.resource_group_name
  ADDRESS_SPACE       = "10.1.3.0/24"
  ISDEPLOYVMTEST      = false
  ISDEPLOYVMTESTPUBIP = false
  TAGS = {
    "prefix" = var.PREFIX
    "branch" = var.BRANCH
  }
}

module "vnetlab1-vmhyperv1" {
  depends_on      = [module.vnetlab1]
  source          = "../modules/vmwindowsgeneric-mod/"
  REGION          = var.REGION
  SUBNETID        = "${module.vnetlab1.vnet1.id}/subnets/general1-snet"
  RGNAME          = module.vnetlab1.vnet1.resource_group_name
  VMNAME          = "lab1-hyperv1"
  VMSKU           = "Standard_D4as_V5"
  VMDATADISK1SIZE = 1024
  ISDEPLOYPUBIP   = true
}

module "vnetlab1-vmkvm1" {
  depends_on      = [module.vnetlab1]
  source          = "../modules/vmlinuxgeneric-mod/"
  REGION          = var.REGION
  SUBNETID        = "${module.vnetlab1.vnet1.id}/subnets/general1-snet"
  RGNAME          = module.vnetlab1.vnet1.resource_group_name
  VMNAME          = "lab1-kvm1"
  VMSKU           = "Standard_D4as_V5"
  VMDATADISK1SIZE = 1024
  ISDEPLOYPUBIP   = true
}

output "vmkvm1" {
  value = {
    name       = module.vnetlab1-vmkvm1.vm1.name
    private_ip = module.vnetlab1-vmkvm1.vm1.private_ip_address
    publicip   = module.vnetlab1-vmkvm1.vm1.public_ip_address
  }
}

output "vmhyperv1" {
  value = {
    name       = module.vnetlab1-vmhyperv1.vm1.name
    private_ip = module.vnetlab1-vmhyperv1.vm1.private_ip_address
    publicip   = module.vnetlab1-vmhyperv1.vm1.public_ip_address
  }
}

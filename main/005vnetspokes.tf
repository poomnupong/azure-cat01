# create test spokes vnets

module "vnetspoke1" {
  depends_on          = [module.vnethub1]
  source              = "../modules/vnetspoketest-mod/"
  REGION              = var.REGION
  RESOURCENAME        = "${var.PREFIX}-${var.BRANCH}-spoketest1-${var.REGION}"
  HUB_VNET_ID         = module.vnethub1.vnet1.id
  HUB_VNET_NAME       = module.vnethub1.vnet1.name
  HUB_VNET_RG         = module.vnethub1.vnet1.resource_group_name
  ADDRESS_SPACE       = "10.1.4.0/24"
  ISDEPLOYVMTEST      = true
  ISDEPLOYVMTESTPUBIP = false
  TAGS = {
    "prefix" = var.PREFIX
    "branch" = var.BRANCH
  }
}

module "vnetspoke2" {
  depends_on          = [module.vnethub1]
  source              = "../modules/vnetspoketest-mod/"
  REGION              = var.REGION
  RESOURCENAME        = "${var.PREFIX}-${var.BRANCH}-spoketest2-${var.REGION}"
  HUB_VNET_ID         = module.vnethub1.vnet1.id
  HUB_VNET_NAME       = module.vnethub1.vnet1.name
  HUB_VNET_RG         = module.vnethub1.vnet1.resource_group_name
  ADDRESS_SPACE       = "10.1.5.0/24"
  ISDEPLOYVMTEST      = true
  ISDEPLOYVMTESTPUBIP = false
  TAGS = {
    "prefix" = var.PREFIX
    "branch" = var.BRANCH
  }
}

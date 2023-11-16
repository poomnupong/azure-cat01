// Main template

# create hub vnet
module "vnethub1" {
  source              = "../modules/vnethubgeneric-mod/"
  REGION              = var.REGION
  RESOURCENAME        = "${var.PREFIX}-${var.BRANCH}-hub1-${var.REGION}"
  ISDEPLOYGWEXR       = false
  ISDEPLOYROUTESERVER = false
  ISDEPLOYAZFW        = false
  GWVPNASNUMBER       = 65001
  ADDRESS_SPACE       = "10.1.1.0/24"
  TAGS = {
    "prefix" = var.PREFIX
    "branch" = var.BRANCH
  }
}

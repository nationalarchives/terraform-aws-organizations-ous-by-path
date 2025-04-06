data "aws_organizations_organization" "org" {}

locals {
  org_id         = data.aws_organizations_organization.org.id
  root_id        = data.aws_organizations_organization.org.roots[0].id
  id_path_prefix = "${local.org_id}/${local.root_id}/"
}

# Level 1 OUs (under Root)
module "level1_ous" {
  source = "./modules/get_sub_ous"
  # Mock a "level0_ous" module output for the root.
  parent_level_ou_list = [{
    id        = local.root_id
    id_path   = local.id_path_prefix
    name_path = ""
  }]
  name_path_delimiter = var.name_path_delimiter
}

module "level2_ous" {
  source               = "./modules/get_sub_ous"
  parent_level_ou_list = module.level1_ous.list
  name_path_delimiter  = var.name_path_delimiter
}

module "level3_ous" {
  source               = "./modules/get_sub_ous"
  parent_level_ou_list = module.level2_ous.list
  name_path_delimiter  = var.name_path_delimiter
}

module "level4_ous" {
  source               = "./modules/get_sub_ous"
  parent_level_ou_list = module.level3_ous.list
  name_path_delimiter  = var.name_path_delimiter
}

module "level5_ous" {
  source               = "./modules/get_sub_ous"
  parent_level_ou_list = module.level4_ous.list
  name_path_delimiter  = var.name_path_delimiter
}

# AWS Quota limit, "OU maximum nesting in a root: Five levels of OUs deep under a root."
# https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html

locals {
  all_ous = concat(
    module.level1_ous.list,
    module.level2_ous.list,
    module.level3_ous.list,
    module.level4_ous.list,
    module.level5_ous.list
  )
}

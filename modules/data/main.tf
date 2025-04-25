data "aws_organizations_organization" "org" {}

locals {
  org_id         = data.aws_organizations_organization.org.id
  root_id        = data.aws_organizations_organization.org.roots[0].id
  id_path_prefix = "${local.org_id}/${local.root_id}/"
}

module "l1" {
  source               = "./modules/get_sub_ous"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = var.name_path_delimiter
  # Mock a "level0_ous" module output for the root.
  parent_level_ou_list = [{
    id        = local.root_id
    id_path   = local.id_path_prefix
    name_path = ""
  }]
}

module "l2" {
  source               = "./modules/get_sub_ous"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = var.name_path_delimiter
  parent_level_ou_list = module.l1.list
}

module "l3" {
  source               = "./modules/get_sub_ous"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = var.name_path_delimiter
  parent_level_ou_list = module.l2.list
}

module "l4" {
  source               = "./modules/get_sub_ous"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = var.name_path_delimiter
  parent_level_ou_list = module.l3.list
}

module "l5" {
  source               = "./modules/get_sub_ous"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = var.name_path_delimiter
  parent_level_ou_list = module.l4.list
}

# AWS Quota limit, "OU maximum nesting in a root: Five levels of OUs deep under a root."
# https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html

locals {
  all_ous = concat(
    module.l1.list,
    module.l2.list,
    module.l3.list,
    module.l4.list,
    module.l5.list
  )

  # Add descendant account lists (if required)
  ous_with_descendant_accounts = !var.include_descendant_accounts ? [] : [for ou in local.all_ous : merge(ou, {
    descendant_accounts = flatten([for i in local.all_ous : i.child_accounts if strcontains(i.id_path, ou.id)])
  })]

  output_list = var.include_descendant_accounts ? local.ous_with_descendant_accounts : local.all_ous
}

data "aws_organizations_organization" "org" {}

locals {
  # Hardcode a delimiter to use internally for the name path, this allows the module caller to change the delimiter variable without destroying everything.
  internal_name_path_delimiter = ":::"

  org_id         = data.aws_organizations_organization.org.id
  root_id        = data.aws_organizations_organization.org.roots[0].id
  id_path_prefix = "${local.org_id}/${local.root_id}/"

  # Convert the nested map structure into a flat list of name paths - "Level 1/Level 2/Level 3/Level 4/Level 5"
  # Terraform can't do recursion, so we have to do this manually.
  ou_list = flatten([
    for l1_k, l1_v in var.organization_structure : [
      l1_k,
      [
        for l2_k, l2_v in try(l1_v, {}) : [
          join(local.internal_name_path_delimiter, [l1_k, l2_k]),
          [
            for l3_k, l3_v in try(l2_v, {}) : [
              join(local.internal_name_path_delimiter, [l1_k, l2_k, l3_k]),
              [
                for l4_k, l4_v in try(l3_v, {}) : [
                  join(local.internal_name_path_delimiter, [l1_k, l2_k, l3_k, l4_k]),
                  [
                    for l5_k, l5_v in try(l4_v, {}) : [
                      join(local.internal_name_path_delimiter, [l1_k, l2_k, l3_k, l4_k, l5_k])
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ])
}

module "l1" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ou_name_paths        = [for i in local.ou_list : join(local.internal_name_path_delimiter, slice(split(local.internal_name_path_delimiter, i), 0, 1)) if length(split(local.internal_name_path_delimiter, i)) >= 1]
  # Mock a "l0" module output for the root.
  parent_level_ou_map = { "Root" = {
    id        = local.root_id
    id_path   = local.id_path_prefix
    name_path = ""
  } }
}

module "l2" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ou_name_paths        = [for i in local.ou_list : join(local.internal_name_path_delimiter, slice(split(local.internal_name_path_delimiter, i), 0, 2)) if length(split(local.internal_name_path_delimiter, i)) >= 2]
  parent_level_ou_map  = module.l1.map
}

module "l3" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ou_name_paths        = [for i in local.ou_list : join(local.internal_name_path_delimiter, slice(split(local.internal_name_path_delimiter, i), 0, 3)) if length(split(local.internal_name_path_delimiter, i)) >= 3]
  parent_level_ou_map  = module.l2.map
}

module "l4" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ou_name_paths        = [for i in local.ou_list : join(local.internal_name_path_delimiter, slice(split(local.internal_name_path_delimiter, i), 0, 4)) if length(split(local.internal_name_path_delimiter, i)) >= 4]
  parent_level_ou_map  = module.l3.map
}

module "l5" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ou_name_paths        = [for i in local.ou_list : join(local.internal_name_path_delimiter, slice(split(local.internal_name_path_delimiter, i), 0, 5)) if length(split(local.internal_name_path_delimiter, i)) >= 5]
  parent_level_ou_map  = module.l4.map
}

# AWS Quota limit, "OU maximum nesting in a root: Five levels of OUs deep under a root."
# https://docs.aws.amazon.com/organizations/latest/userguide/orgs_reference_limits.html

locals {
  all_ous_internal = merge(
    module.l1.map,
    module.l2.map,
    module.l3.map,
    module.l4.map,
    module.l5.map
  )

  output_map = { for name_path, ou in local.all_ous_internal : replace(ou.name_path, local.internal_name_path_delimiter, var.name_path_delimiter) => merge(
    ou,
    { name_path = replace(ou.name_path, local.internal_name_path_delimiter, var.name_path_delimiter) },
    !var.include_descendant_accounts ? {} : { descendant_accounts = flatten([for i in local.all_ous_internal : i.child_accounts if strcontains(i.id_path, ou.id)]) }
    )
  }
}

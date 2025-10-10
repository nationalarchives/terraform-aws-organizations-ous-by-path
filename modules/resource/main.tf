data "aws_organizations_organization" "org" {}

locals {
  # Hardcode a delimiter to use internally for the name path, this allows the module caller to change var.name_path_delimiter without destroying everything.
  internal_name_path_delimiter = ":::"

  org_id          = data.aws_organizations_organization.org.id
  root_id         = data.aws_organizations_organization.org.roots[0].id
  org_path_prefix = "${local.org_id}/${local.root_id}/"

  # Convert the nested map structure into a map of objects with paths and tags
  # { "Level1:::Level2:::Level3:::Level4:::Level5" : {"tags": {"key": "value"} }
  # Terraform can't do recursion, so we have to do this manually.
  l0_cascading_tags = lookup(var.organization_structure, var.cascading_tags_key, {})
  ous_to_create = {
    for ou_path in concat(
      # Level 1
      [for l1_k, l1_v in var.organization_structure : {
        path = l1_k
        tags = merge(
          local.l0_cascading_tags,
          lookup(l1_v, var.cascading_tags_key, {}),
          lookup(l1_v, var.static_tags_key, {})
        )
      } if !contains([var.cascading_tags_key, var.static_tags_key], l1_k)],
      # Level 2
      flatten([for l1_k, l1_v in var.organization_structure :
        [for l2_k, l2_v in try(l1_v, {}) : {
          path = join(local.internal_name_path_delimiter, [l1_k, l2_k])
          tags = merge(
            local.l0_cascading_tags,
            lookup(l1_v, var.cascading_tags_key, {}),
            lookup(l2_v, var.cascading_tags_key, {}),
            lookup(l2_v, var.static_tags_key, {})
          )
        } if !contains([var.cascading_tags_key, var.static_tags_key], l2_k)]
      if !contains([var.cascading_tags_key, var.static_tags_key], l1_k)]),
      # Level 3
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          [for l3_k, l3_v in try(l2_v, {}) : {
            path = join(local.internal_name_path_delimiter, [l1_k, l2_k, l3_k])
            tags = merge(
              local.l0_cascading_tags,
              lookup(l1_v, var.cascading_tags_key, {}),
              lookup(l2_v, var.cascading_tags_key, {}),
              lookup(l3_v, var.cascading_tags_key, {}),
              lookup(l3_v, var.static_tags_key, {})
            )
          } if !contains([var.cascading_tags_key, var.static_tags_key], l3_k)]
        if !contains([var.cascading_tags_key, var.static_tags_key], l2_k)])
      if !contains([var.cascading_tags_key, var.static_tags_key], l1_k)]),
      # Level 4
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          flatten([for l3_k, l3_v in try(l2_v, {}) :
            [for l4_k, l4_v in try(l3_v, {}) : {
              path = join(local.internal_name_path_delimiter, [l1_k, l2_k, l3_k, l4_k])
              tags = merge(
                local.l0_cascading_tags,
                lookup(l1_v, var.cascading_tags_key, {}),
                lookup(l2_v, var.cascading_tags_key, {}),
                lookup(l3_v, var.cascading_tags_key, {}),
                lookup(l4_v, var.cascading_tags_key, {}),
                lookup(l4_v, var.static_tags_key, {})
              )
            } if !contains([var.cascading_tags_key, var.static_tags_key], l4_k)]
          if !contains([var.cascading_tags_key, var.static_tags_key], l3_k)])
        if !contains([var.cascading_tags_key, var.static_tags_key], l2_k)])
      if !contains([var.cascading_tags_key, var.static_tags_key], l1_k)]),
      # Level 5
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          flatten([for l3_k, l3_v in try(l2_v, {}) :
            flatten([for l4_k, l4_v in try(l3_v, {}) :
              [for l5_k, l5_v in try(l4_v, {}) : {
                path = join(local.internal_name_path_delimiter, [l1_k, l2_k, l3_k, l4_k, l5_k])
                tags = merge(
                  local.l0_cascading_tags,
                  lookup(l1_v, var.cascading_tags_key, {}),
                  lookup(l2_v, var.cascading_tags_key, {}),
                  lookup(l3_v, var.cascading_tags_key, {}),
                  lookup(l4_v, var.cascading_tags_key, {}),
                  lookup(l5_v, var.cascading_tags_key, {}),
                  lookup(l5_v, var.static_tags_key, {})
                )
              } if !contains([var.cascading_tags_key, var.static_tags_key], l5_k)]
            if !contains([var.cascading_tags_key, var.static_tags_key], l4_k)])
          if !contains([var.cascading_tags_key, var.static_tags_key], l3_k)])
        if !contains([var.cascading_tags_key, var.static_tags_key], l2_k)])
      if !contains([var.cascading_tags_key, var.static_tags_key], l1_k)])
      ) : ou_path.path => {
      tags = ou_path.tags
    }
  }

}

# Create the OUs
module "l1" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ous                  = { for k, v in local.ous_to_create : k => v if length(split(local.internal_name_path_delimiter, k)) == 1 }
  # Mock a "l0" module output for the root.
  parent_level_ou_map = { "Root" = {
    id        = local.root_id
    name_path = ""
    org_path  = local.org_path_prefix
  } }
}

module "l2" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ous                  = { for k, v in local.ous_to_create : k => v if length(split(local.internal_name_path_delimiter, k)) == 2 }
  parent_level_ou_map  = module.l1.map
}

module "l3" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ous                  = { for k, v in local.ous_to_create : k => v if length(split(local.internal_name_path_delimiter, k)) == 3 }
  parent_level_ou_map  = module.l2.map
}

module "l4" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ous                  = { for k, v in local.ous_to_create : k => v if length(split(local.internal_name_path_delimiter, k)) == 4 }
  parent_level_ou_map  = module.l3.map
}

module "l5" {
  source               = "./modules/ou_level"
  include_aws_accounts = var.include_child_accounts
  name_path_delimiter  = local.internal_name_path_delimiter
  ous                  = { for k, v in local.ous_to_create : k => v if length(split(local.internal_name_path_delimiter, k)) == 5 }
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
    !var.include_descendant_accounts ? {} : { descendant_accounts = flatten([for i in local.all_ous_internal : i.child_accounts if strcontains(i.org_path, ou.id)]) }
    )
  }
}

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
  ous_to_create = {
    for ou_path in concat(
      # Level 1
      [for l1_k, l1_v in var.organization_structure : {
        path = l1_k
        tags = var.ou_tags_key != null ? try(l1_v[var.ou_tags_key], {}) : {}
      }],
      # Level 2
      flatten([for l1_k, l1_v in var.organization_structure :
        [for l2_k, l2_v in try(l1_v, {}) : {
          path = join(local.internal_name_path_delimiter, [l1_k, l2_k])
          tags = var.ou_tags_key != null ? try(l2_v[var.ou_tags_key], {}) : {}
        } if l2_k != var.ou_tags_key]
      ]),
      # Level 3
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          [for l3_k, l3_v in try(l2_v, {}) : {
            path = join(local.internal_name_path_delimiter, [l1_k, l2_k, l3_k])
            tags = var.ou_tags_key != null ? try(l3_v[var.ou_tags_key], {}) : {}
          } if l3_k != var.ou_tags_key]
          if l2_k != var.ou_tags_key
        ])
      ]),
      # Level 4
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          flatten([for l3_k, l3_v in try(l2_v, {}) :
            [for l4_k, l4_v in try(l3_v, {}) : {
              path = join(local.internal_name_path_delimiter, [l1_k, l2_k, l3_k, l4_k])
              tags = var.ou_tags_key != null ? try(l4_v[var.ou_tags_key], {}) : {}
            } if l4_k != var.ou_tags_key]
            if l3_k != var.ou_tags_key
          ])
          if l2_k != var.ou_tags_key
        ])
      ]),
      # Level 5
      flatten([for l1_k, l1_v in var.organization_structure :
        flatten([for l2_k, l2_v in try(l1_v, {}) :
          flatten([for l3_k, l3_v in try(l2_v, {}) :
            flatten([for l4_k, l4_v in try(l3_v, {}) :
              [for l5_k, l5_v in try(l4_v, {}) : {
                path = join(local.internal_name_path_delimiter, [l1_k, l2_k, l3_k, l4_k, l5_k])
                tags = var.ou_tags_key != null ? try(l5_v[var.ou_tags_key], {}) : {}
              } if l5_k != var.ou_tags_key]
              if l4_k != var.ou_tags_key
            ])
            if l3_k != var.ou_tags_key
          ])
          if l2_k != var.ou_tags_key
        ])
      ])
      ) : ou_path.path => {
      tags = ou_path.tags
    }
  }

}

# Create the OUs

#[for i in local.ou_list : join(local.internal_name_path_delimiter, slice(split(local.internal_name_path_delimiter, i), 0, 1)) if length(split(local.internal_name_path_delimiter, i)) >= 1]

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

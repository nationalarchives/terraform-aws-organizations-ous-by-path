locals {
  parent_level_ou_map = { for ou in var.parent_level_ou_list : ou.id => ou }
  is_level1           = length(var.parent_level_ou_list) == 1 && try(startswith(var.parent_level_ou_list[0].id, "r-"), false)
}

data "aws_organizations_organizational_units" "ous" {
  for_each  = local.parent_level_ou_map
  parent_id = each.key
}

data "aws_organizations_resource_tags" "ous" {
  for_each    = toset(!var.include_ou_tags ? [] : flatten([for parent_ou in data.aws_organizations_organizational_units.ous : [for child in parent_ou.children : child.id]]))
  resource_id = each.key
}

data "aws_organizations_organizational_unit_child_accounts" "child_accounts" {
  for_each  = toset(!var.include_aws_accounts ? [] : flatten([for parent_ou in data.aws_organizations_organizational_units.ous : [for child in parent_ou.children : child.id]]))
  parent_id = each.key
}

locals {
  ous = flatten([
    for parent_id, ou_data in data.aws_organizations_organizational_units.ous : [
      for ou in ou_data.children : {
        arn = ou.arn
        child_accounts = !var.include_aws_accounts ? [] : [for account in data.aws_organizations_organizational_unit_child_accounts.child_accounts[ou.id].accounts : {
          arn   = account.arn
          email = account.email
          id    = account.id
          name  = account.name
        }]
        descendant_accounts = []
        id                  = ou.id
        name                = ou.name
        name_path           = local.is_level1 ? ou.name : "${local.parent_level_ou_map[parent_id].name_path}${var.name_path_delimiter}${ou.name}"
        org_path            = "${local.parent_level_ou_map[parent_id].org_path}${ou.id}/"
        parent_id           = parent_id
        tags                = try(data.aws_organizations_resource_tags.ous[ou.id].tags, {})
      }
    ]
  ])
}

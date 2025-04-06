locals {
  parent_level_ou_map = { for ou in var.parent_level_ou_list : ou.id => ou }
  is_level1           = length(var.parent_level_ou_list) == 1 && startswith(var.parent_level_ou_list[0].id, "r-")
}

data "aws_organizations_organizational_units" "sub_ous" {
  for_each  = local.parent_level_ou_map
  parent_id = each.key
}

data "aws_organizations_organizational_unit_child_accounts" "sub_ou_child_accounts" {
  for_each  = !var.include_aws_accounts ? [] : toset(flatten([for parent_ou in data.aws_organizations_organizational_units.sub_ous : [for child in parent_ou.children : child.id]]))
  parent_id = each.key
}

locals {
  sub_ous = flatten([
    for parent_id, ou_data in data.aws_organizations_organizational_units.sub_ous : [
      for ou in ou_data.children : merge(
        ou,
        {
          id_path             = "${local.parent_level_ou_map[parent_id].id_path}${ou.id}/"
          name_path           = local.is_level1 ? ou.name : "${local.parent_level_ou_map[parent_id].name_path}${var.name_path_delimiter}${ou.name}"
          parent_id           = parent_id
          child_accounts      = !var.include_aws_accounts ? null : data.aws_organizations_organizational_unit_child_accounts.sub_ou_child_accounts[ou.id].accounts
          descendant_accounts = null
        }
      )
    ]
  ])
}

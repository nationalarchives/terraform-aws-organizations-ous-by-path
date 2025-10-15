locals {
  is_level1 = length(var.parent_level_ou_map) == 1 && try(startswith(var.parent_level_ou_map["Root"].id, "r-"), false)
}

resource "aws_organizations_organizational_unit" "ous" {
  for_each  = var.ous
  name      = element(split(var.name_path_delimiter, each.key), -1)
  parent_id = local.is_level1 ? var.parent_level_ou_map["Root"].id : var.parent_level_ou_map[trimsuffix(each.key, "${var.name_path_delimiter}${element(split(var.name_path_delimiter, each.key), -1)}")].id
  tags      = each.value.tags
}

locals {
  output_map = { for name_path, ou in aws_organizations_organizational_unit.ous : name_path => {
    arn = ou.arn
    child_accounts = !var.include_aws_accounts ? [] : [for account in ou.accounts : {
      arn   = account.arn
      email = account.email
      id    = account.id
      name  = account.name
    }]
    descendant_accounts = []
    id                  = ou.id
    name                = ou.name
    name_path           = name_path
    org_path            = local.is_level1 ? "${var.parent_level_ou_map["Root"].org_path}${ou.id}/" : join("", [var.parent_level_ou_map[trimsuffix(name_path, "${var.name_path_delimiter}${element(split(var.name_path_delimiter, name_path), -1)}")].org_path, ou.id, "/"])
    parent_id           = ou.parent_id
    tags                = ou.tags_all
    }
  }
}

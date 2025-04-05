data "aws_organizations_organization" "org" {}

locals {
  org_id  = data.aws_organizations_organization.org.id
  root_id = data.aws_organizations_organization.org.roots[0].id
}

# Level 1 OUs (under Root)
data "aws_organizations_organizational_units" "level1" {
  parent_id = local.root_id
}

locals {
  level1_ous = [
    for ou in data.aws_organizations_organizational_units.level1.children : {
      id        = ou.id
      name      = ou.name
      parent_id = local.root_id
      id_path   = "${local.org_id}/${local.root_id}/${ou.id}/"
      name_path = "${ou.name}"
    }
  ]
  level1_ou_map = { for ou in local.level1_ous : ou.id => ou }
}

# Level 2 OUs
data "aws_organizations_organizational_units" "level2" {
  for_each  = local.level1_ou_map
  parent_id = each.key
}

locals {
  level2_ous = flatten([
    for parent_id, ou_data in data.aws_organizations_organizational_units.level2 : [
      for ou in ou_data.children : {
        id        = ou.id
        name      = ou.name
        parent_id = parent_id
        id_path   = "${local.level1_ou_map[parent_id].id_path}${ou.id}/"
        name_path = join(var.name_path_delimiter, [local.level1_ou_map[parent_id].name_path, ou.name])
      }
    ]
  ])
  level2_ou_map = { for ou in local.level2_ous : ou.id => ou }
}

# Level 3 OUs
data "aws_organizations_organizational_units" "level3" {
  for_each  = local.level2_ou_map
  parent_id = each.key
}

locals {
  level3_ous = flatten([
    for parent_id, ou_data in data.aws_organizations_organizational_units.level3 : [
      for ou in ou_data.children : {
        id        = ou.id
        name      = ou.name
        parent_id = parent_id
        id_path   = "${local.level2_ou_map[parent_id].id_path}${ou.id}/"
        name_path = join(var.name_path_delimiter, [local.level2_ou_map[parent_id].name_path, ou.name])
      }
    ]
  ])
  level3_ou_map = { for ou in local.level3_ous : ou.id => ou }
}

# Level 4 OUs
data "aws_organizations_organizational_units" "level4" {
  for_each  = local.level3_ou_map
  parent_id = each.key
}

locals {
  level4_ous = flatten([
    for parent_id, ou_data in data.aws_organizations_organizational_units.level4 : [
      for ou in ou_data.children : {
        id        = ou.id
        name      = ou.name
        parent_id = parent_id
        id_path   = "${local.level3_ou_map[parent_id].id_path}${ou.id}/"
        name_path = join(var.name_path_delimiter, [local.level3_ou_map[parent_id].name_path, ou.name])
      }
    ]
  ])
  level4_ou_map = { for ou in local.level4_ous : ou.id => ou }
}

# Level 5 OUs (AWS Quota limit)
data "aws_organizations_organizational_units" "level5" {
  for_each  = local.level4_ou_map
  parent_id = each.key
}

locals {
  level5_ous = flatten([
    for parent_id, ou_data in data.aws_organizations_organizational_units.level5 : [
      for ou in ou_data.children : {
        id        = ou.id
        name      = ou.name
        parent_id = parent_id
        id_path   = "${local.level4_ou_map[parent_id].id_path}${ou.id}/"
        name_path = join(var.name_path_delimiter, [local.level4_ou_map[parent_id].name_path, ou.name])
      }
    ]
  ])
}

locals {
  all_ous = concat(
    local.level1_ous,
    local.level2_ous,
    local.level3_ous,
    local.level4_ous,
    local.level5_ous
  )
}

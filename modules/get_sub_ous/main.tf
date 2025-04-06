variable "parent_level_ou_list" {
  description = "output.list from the previous level of OUs."
  type = list(object({
    id        = string
    id_path   = string
    name_path = string
  }))
}

variable "name_path_delimiter" {
  description = "Delimiter used to join names in the name_path attribute of each OU."
  type        = string
}

locals {
  parent_level_ou_map = { for ou in var.parent_level_ou_list : ou.id => ou }
}

data "aws_organizations_organizational_units" "sub_ous" {
  for_each  = local.parent_level_ou_map
  parent_id = each.key
}

locals {
  sub_ous = flatten([
    for parent_id, ou_data in data.aws_organizations_organizational_units.sub_ous : [
      for ou in ou_data.children : merge(ou, {
        id_path   = "${local.parent_level_ou_map[parent_id].id_path}${ou.id}/"
        name_path = length(local.parent_level_ou_map[parent_id].name_path) > 0 ? "${local.parent_level_ou_map[parent_id].name_path}${var.name_path_delimiter}${ou.name}" : ou.name
        parent_id = parent_id
      })
    ]
  ])
}

output "list" {
  description = "List of all OUs with added attributes."
  value       = local.sub_ous
}

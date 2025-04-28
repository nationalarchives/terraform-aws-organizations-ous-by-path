locals {
  is_resource = length(var.organization_structure) > 0 ? true : false
}

module "data" {
  count  = local.is_resource ? 0 : 1
  source = "./modules/data"

  include_child_accounts      = var.include_child_accounts
  include_descendant_accounts = var.include_descendant_accounts
  name_path_delimiter         = var.name_path_delimiter
}

module "resource" {
  count  = local.is_resource ? 1 : 0
  source = "./modules/resource"

  include_child_accounts      = var.include_child_accounts
  include_descendant_accounts = var.include_descendant_accounts
  name_path_delimiter         = var.name_path_delimiter
  organization_structure      = var.organization_structure
}

locals {
  output_map = try(module.data[0].by_name_path, module.resource[0].by_name_path)
}

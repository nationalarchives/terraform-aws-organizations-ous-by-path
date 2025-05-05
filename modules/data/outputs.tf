output "by_id" {
  description = "Map of all OUs indexed by id."
  value       = { for ou in local.output_list : ou.id => ou }
}

output "by_name_path" {
  description = "Map of all OUs indexed by name_path."
  value       = { for ou in local.output_list : ou.name_path => ou }
}

output "list" {
  description = "List of all OUs with added attributes name_path and org_path."
  value       = local.output_list
}

output "by_id" {
  description = "Map of managed OUs indexed by id."
  value       = { for ou in local.output_map : ou.id => ou }
}

output "by_name_path" {
  description = "Map of managed OUs indexed by name_path."
  value       = local.output_map
}

output "list" {
  description = "List of managed OUs with added attributes name_path and org_path."
  value       = [for ou in local.output_map : ou]
}

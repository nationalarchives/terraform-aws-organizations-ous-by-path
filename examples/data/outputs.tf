output "backup_ou" {
  description = "Backup OU ID."
  value       = module.ous.by_name_path["Backup"].id
}

output "app_prod_ou" {
  description = "Application Production OU ID."
  value       = module.ous.by_name_path["Workloads / Application / Production"].id
}
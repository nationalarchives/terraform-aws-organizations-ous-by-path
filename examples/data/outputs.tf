output "backup_ou_id" {
  description = "Backup OU ID."
  value       = module.ous.by_name_path["Backup"].id
}

output "app_prod_ou_id" {
  description = "Application Production OU ID."
  value       = module.ous.by_name_path["Workloads / Application / Production"].id
}

output "serverless_ou_tags" {
  description = "Map of tags associated with the Serverless OU."
  value       = module.ous.by_name_path["Workloads / Serverless"].tags
}

# outputs.tf - файл для определения выходных данных модуля

output "policy_id" {
  description = "Идентификатор созданной политики резервного копирования."
  value       = yandex_backup_policy.backup_policy.id
}

output "policy_name" {
  description = "Имя созданной политики резервного копирования."
  value       = yandex_backup_policy.backup_policy.name
}

output "policy_created_at" {
  description = "Время создания политики резервного копирования."
  value       = yandex_backup_policy.backup_policy.created_at
}

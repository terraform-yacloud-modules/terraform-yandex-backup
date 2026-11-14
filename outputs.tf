output "policy_id" {
  description = "ID политики резервного копирования"
  value       = yandex_backup_policy.backup_policy.id
}

output "policy_name" {
  description = "Имя политики резервного копирования"
  value       = yandex_backup_policy.backup_policy.name
}

output "policy_enabled" {
  description = "Признак включённости политики резервного копирования"
  value       = yandex_backup_policy.backup_policy.enabled
}

output "policy_created_at" {
  description = "Дата и время создания политики резервного копирования"
  value       = yandex_backup_policy.backup_policy.created_at
}

output "policy_binding_id" {
  description = "ID привязки политики резервного копирования к виртуальной машине"
  value       = try(yandex_backup_policy_bindings.policy_binding[0].id, null)
}

output "policy_binding_ids" {
  description = "Карта привязок политики к ВМ: ключ — ID экземпляра, значение — ID привязки"
  value = merge(
    var.create_multiple_policy_bindings ? {
      for index, instance_id in var.policy_binding_instance_ids :
      instance_id => yandex_backup_policy_bindings.policy_bindings[index].id
    } : {},
    var.create_policy_binding ? { (var.policy_binding_instance_id) = yandex_backup_policy_bindings.policy_binding[0].id } : {},
  )
}

output "policy_binding_created_at" {
  description = "Дата и время создания привязки политики к виртуальной машине"
  value       = try(yandex_backup_policy_bindings.policy_binding[0].created_at, null)
}

output "instance_ids" {
  description = "ID виртуальных машин, к которым привязана политика"
  value       = [for instance in module.yandex_compute_instance : instance.instance_id]
}

output "daily_policy_id" {
  description = "ID политики с календарным расписанием"
  value       = module.daily_backup_policy.policy_id
}

output "daily_policy_binding_ids" {
  description = "Карта привязок политики к ВМ: ключ — ID экземпляра, значение — ID привязки"
  value       = module.daily_backup_policy.policy_binding_ids
}

output "interval_policy_id" {
  description = "ID политики с интервальным расписанием"
  value       = module.interval_backup_policy.policy_id
}

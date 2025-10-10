resource "yandex_backup_policy" "backup_policy" {
  name                              = var.name
  archive_name                      = var.archive_name
  cbt                               = var.cbt
  compression                       = var.compression
  fast_backup_enabled               = var.fast_backup_enabled
  format                            = var.format
  multi_volume_snapshotting_enabled = var.multi_volume_snapshotting_enabled
  performance_window_enabled        = var.performance_window_enabled
  silent_mode_enabled               = var.silent_mode_enabled
  splitting_bytes                   = var.splitting_bytes
  vss_provider                      = var.vss_provider

  reattempts {
    enabled      = var.reattempts.enabled
    interval     = var.reattempts.interval
    max_attempts = var.reattempts.max_attempts
  }

  retention {
    after_backup = var.retention.after_backup

    dynamic "rules" {
      for_each = var.retention.rules
      content {
        max_age       = lookup(rules.value, "max_age", null)
        max_count     = lookup(rules.value, "max_count", null)
        repeat_period = lookup(rules.value, "repeat_period", [])
      }
    }
  }

  scheduling {
    enabled              = var.scheduling.enabled
    max_parallel_backups = var.scheduling.max_parallel_backups
    random_max_delay     = var.scheduling.random_max_delay
    scheme               = var.scheduling.scheme
    weekly_backup_day    = var.scheduling.weekly_backup_day

    dynamic "backup_sets" {
      for_each = var.scheduling.backup_sets
      content {
        execute_by_time {
          type                      = lookup(backup_sets.value, "type", null)
          include_last_day_of_month = lookup(backup_sets.value, "include_last_day_of_month", false)
          monthdays                 = lookup(backup_sets.value, "monthdays", [])
          months                    = lookup(backup_sets.value, "months", [])
          repeat_at                 = lookup(backup_sets.value, "repeat_at", [])
          repeat_every              = lookup(backup_sets.value, "repeat_every", null)
          weekdays                  = lookup(backup_sets.value, "weekdays", [])
        }
      }
    }
  }

  vm_snapshot_reattempts {
    enabled      = var.vm_snapshot_reattempts.enabled
    interval     = var.vm_snapshot_reattempts.interval
    max_attempts = var.vm_snapshot_reattempts.max_attempts
  }
}

# Ресурс для привязки политики резервного копирования к ВМ
resource "yandex_backup_policy_bindings" "policy_binding" {
  count = var.create_policy_binding ? 1 : 0

  instance_id = var.policy_binding_instance_id
  policy_id   = yandex_backup_policy.backup_policy.id

  dynamic "timeouts" {
    for_each = var.policy_binding_timeouts != null ? [var.policy_binding_timeouts] : []
    content {
      create = lookup(timeouts.value, "create", null)
      read   = lookup(timeouts.value, "read", null)
      update = lookup(timeouts.value, "update", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}

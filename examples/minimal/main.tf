module "daily_backup_policy" {
  # Путь к папке с файлами модуля
  source = "../.."

  # Переопределяем только необходимые параметры
  name = "my-daily-backup-policy"

  scheduling = {
    enabled              = true
    max_parallel_backups = 2
    random_max_delay     = "15m"
    scheme               = "ALWAYS_INCREMENTAL"
    weekly_backup_day    = "MONDAY" # не используется в DAILY, но должен быть указан
    backup_sets = [
      {
        type      = "DAILY"
        repeat_at = ["02:00"] # Ежедневно в 2 часа ночи
      }
    ]
  }

  retention = {
    after_backup = true
    rules = [
      {
        # Хранить копии, сделанные за последние 14 дней
        max_age = "14d"
      }
    ]
  }
}

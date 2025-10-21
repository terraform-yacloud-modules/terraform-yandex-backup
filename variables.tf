variable "name" {
  description = "Имя политики резервного копирования. Обязательный параметр."
  type        = string
}

variable "archive_name" {
  description = "Имя сгенерированных архивов. Переменные: [Machine Name], [Plan ID], [Unique ID]. Последний символ имени не должен быть переменной."
  type        = string
  default     = "[Machine Name]-[Plan ID]-[Unique ID]a"
}

variable "cbt" {
  description = "Конфигурация отслеживания содержимого резервных копий (USE_IF_ENABLED, ENABLE_AND_USE, DO_NOT_USE)."
  type        = string
  default     = "DO_NOT_USE"
  validation {
    condition     = contains(["USE_IF_ENABLED", "ENABLE_AND_USE", "DO_NOT_USE"], var.cbt)
    error_message = "Допустимые значения для cbt: USE_IF_ENABLED, ENABLE_AND_USE, DO_NOT_USE."
  }
}

variable "compression" {
  description = "Степень сжатия резервной копии (NORMAL, HIGH, MAX, OFF)."
  type        = string
  default     = "NORMAL"
  validation {
    condition     = contains(["NORMAL", "HIGH", "MAX", "OFF"], var.compression)
    error_message = "Допустимые значения для compression: NORMAL, HIGH, MAX, OFF."
  }
}

variable "fast_backup_enabled" {
  description = "Быстрое резервное копирование для отслеживания изменений в файлах по размеру и временной метке."
  type        = bool
  default     = true
}

variable "format" {
  description = "Формат резервной копии (VERSION_11, VERSION_12, AUTO)."
  type        = string
  default     = "AUTO"
  validation {
    condition     = contains(["VERSION_11", "VERSION_12", "AUTO"], var.format)
    error_message = "Допустимые значения для format: VERSION_11, VERSION_12, AUTO."
  }
}

variable "multi_volume_snapshotting_enabled" {
  description = "Создание резервных копий нескольких томов одновременно."
  type        = bool
  default     = true
}

variable "performance_window_enabled" {
  description = "Временные окна для ограничения производительности резервного копирования."
  type        = bool
  default     = false
}

variable "silent_mode_enabled" {
  description = "Режим тишины, предполагающий минимальное взаимодействие с пользователем."
  type        = bool
  default     = true
}

variable "splitting_bytes" {
  description = "Параметр для определения размера для разделения резервных копий."
  type        = string
  default     = "9223372036854775807"
}

variable "vss_provider" {
  description = "Настройки VSS-службы (NATIVE или TARGET_SYSTEM_DEFINED)."
  type        = string
  default     = "NATIVE"
  validation {
    condition     = contains(["NATIVE", "TARGET_SYSTEM_DEFINED"], var.vss_provider)
    error_message = "Допустимые значения для vss_provider: NATIVE, TARGET_SYSTEM_DEFINED."
  }
}

variable "folder_id" {
  description = "Идентификатор каталога, к которому принадлежит ресурс. Если не указан, используется folder_id провайдера по умолчанию."
  type        = string
  default     = null
}

variable "file_filters" {
  description = "Фильтры файлов для указания масок файлов для резервного копирования или исключения."
  type = object({
    exclusion_masks = optional(list(string), [])
    inclusion_masks = optional(list(string), [])
  })
  default = null
}

variable "lvm_snapshotting_enabled" {
  description = "Будет ли LVM использоваться для создания снимка тома."
  type        = bool
  default     = false
}

variable "sector_by_sector" {
  description = "Посекторное резервное копирование диска или тома."
  type        = bool
  default     = false
}

variable "validation_enabled" {
  description = "Включена ли проверка резервных копий."
  type        = bool
  default     = false
}

variable "timeouts" {
  description = "Настройки таймаутов для ресурса политики резервного копирования."
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

variable "reattempts" {
  description = "Параметры повторения операций резервного копирования в случае сбоев."
  type = object({
    enabled      = bool
    interval     = string
    max_attempts = number
  })
  default = {
    enabled      = true
    interval     = "5m"
    max_attempts = 5
  }
}

variable "retention" {
  description = "Параметры хранения резервных копий."
  type = object({
    after_backup = bool
    rules = list(object({
      max_age       = optional(string)
      max_count     = optional(number)
      repeat_period = optional(list(string))
    }))
  })
  default = {
    after_backup = false
    rules = [
      {
        max_age = "365d"
      }
    ]
  }
}

variable "scheduling" {
  description = "Параметры расписания резервного копирования."
  type = object({
    enabled              = bool
    max_parallel_backups = number
    random_max_delay     = string
    scheme               = string
    weekly_backup_day    = string
    backup_sets = list(object({
      type                      = string
      execute_by_interval       = optional(number)
      include_last_day_of_month = optional(bool, false)
      monthdays                 = optional(list(number))
      months                    = optional(list(number))
      repeat_at                 = optional(list(string))
      repeat_every              = optional(string)
      weekdays                  = optional(list(string))
    }))
  })
  default = {
    enabled              = true
    max_parallel_backups = 0
    random_max_delay     = "30m"
    scheme               = "ALWAYS_INCREMENTAL"
    weekly_backup_day    = "MONDAY"
    backup_sets = [
      {
        type                      = "MONTHLY"
        include_last_day_of_month = true
        months                    = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        repeat_at                 = ["04:10"]
      }
    ]
  }
  validation {
    condition     = contains(["ALWAYS_INCREMENTAL", "ALWAYS_FULL", "WEEKLY_FULL_DAILY_INCREMENTAL", "WEEKLY_INCREMENTAL"], var.scheduling.scheme)
    error_message = "Допустимые значения для scheme: ALWAYS_INCREMENTAL, ALWAYS_FULL, WEEKLY_FULL_DAILY_INCREMENTAL, WEEKLY_INCREMENTAL."
  }
  validation {
    condition     = contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], var.scheduling.weekly_backup_day)
    error_message = "Допустимые значения для weekly_backup_day: MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY."
  }
}

variable "vm_snapshot_reattempts" {
  description = "Параметры повторения операций создания снапшотов ВМ в случае сбоев."
  type = object({
    enabled      = bool
    interval     = string
    max_attempts = number
  })
  default = {
    enabled      = true
    interval     = "5m"
    max_attempts = 5
  }
}

variable "create_policy_binding" {
  description = "Флаг для создания привязки политики к ВМ."
  type        = bool
  default     = false
}

variable "policy_binding_instance_id" {
  description = "ID экземпляра Compute Cloud для привязки политики."
  type        = string
  default     = null
}

variable "policy_binding_timeouts" {
  description = "Настройки таймаутов для привязки политики."
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

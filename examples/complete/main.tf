data "yandex_client_config" "client" {}

provider "yandex" {
}

locals {
  folder_id = coalesce(var.folder_id, data.yandex_client_config.client.folder_id)
  zone      = "ru-central1-d"

  instance_names = ["backup-complete-1", "backup-complete-2"]
}

module "network" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git?ref=v1.0.0"

  folder_id  = local.folder_id
  blank_name = "instance-complete-vpc-nat-gateway"

  azs = [local.zone]

  private_subnets    = [["10.19.0.0/24"]]
  create_vpc         = true
  create_nat_gateway = true
}

module "iam_accounts" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account?ref=v1.0.0"

  name = "backup-complete-iam"
  folder_roles = [
    "editor",
  ]
  cloud_roles              = []
  enable_static_access_key = false
  enable_api_key           = false
  enable_account_key       = false
}

module "yandex_compute_instance" {
  source   = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-instance.git?ref=v1.0.0"
  for_each = toset(local.instance_names)

  folder_id = local.folder_id

  name = each.value

  zone       = local.zone
  subnet_id  = module.network.private_subnets_ids[0]
  enable_nat = true
  create_pip = true

  hostname         = each.value
  generate_ssh_key = true
  ssh_user         = "ubuntu"

  service_account_id = module.iam_accounts.id

  user_data = <<-EOF
        #cloud-config
        package_upgrade: true
        packages:
          - nginx
          - curl
          - perl
          - jq
        runcmd:
          - [systemctl, start, nginx]
          - [systemctl, enable, nginx]
          - curl https://storage.yandexcloud.net/backup-distributions/agent_installer.sh | sudo bash
        EOF
}

# Политика с календарным расписанием: полный бэкап раз в неделю,
# инкрементальный — каждый день. Одна политика привязывается сразу к двум ВМ.
module "daily_backup_policy" {
  source = "../.."

  name         = "complete-daily-backup-policy"
  folder_id    = local.folder_id
  archive_name = "[Machine Name]-[Plan ID]-[Unique ID]a"

  cbt                               = "DO_NOT_USE"
  compression                       = "NORMAL"
  fast_backup_enabled               = true
  format                            = "AUTO"
  lvm_snapshotting_enabled          = false
  multi_volume_snapshotting_enabled = true
  performance_window_enabled        = false
  sector_by_sector                  = false
  silent_mode_enabled               = true
  splitting_bytes                   = "9223372036854775807"
  validation_enabled                = true
  vss_provider                      = "NATIVE"

  file_filters = {
    inclusion_masks = ["/var/www/**", "/etc/nginx/**"]
    exclusion_masks = ["*.log", "*.tmp"]
  }

  reattempts = {
    enabled      = true
    interval     = "10m"
    max_attempts = 3
  }

  retention = {
    after_backup = true
    rules = [
      {
        max_age = "30d"
      },
      {
        max_count     = 10
        repeat_period = ["DAILY"]
      }
    ]
  }

  scheduling = {
    enabled = true
    # Cloud Backup API не сохраняет ненулевое значение: возвращает 0.
    max_parallel_backups = 0
    random_max_delay     = "15m"
    scheme               = "WEEKLY_FULL_DAILY_INCREMENTAL"
    weekly_backup_day    = "SUNDAY"
    backup_sets = [
      {
        backup_set_type = "TYPE_AUTO"
        type            = "DAILY"
        repeat_at       = ["03:00"]
        run_later       = true
      },
    ]
  }

  vm_snapshot_reattempts = {
    enabled      = true
    interval     = "5m"
    max_attempts = 5
  }

  timeouts = {
    create = "30m"
    read   = "5m"
    update = "10m"
    delete = "10m"
  }

  create_multiple_policy_bindings = true
  policy_binding_instance_ids = [
    for instance in module.yandex_compute_instance : instance.instance_id
  ]

  policy_binding_timeouts = {
    create = "10m"
    read   = "5m"
    delete = "5m"
  }
}

# Политика с интервальным расписанием: бэкап каждые 24 часа.
# Интервал задаётся на уровне набора бэкапов (execute_by_interval).
module "interval_backup_policy" {
  source = "../.."

  name      = "complete-interval-backup-policy"
  folder_id = local.folder_id

  compression                       = "HIGH"
  fast_backup_enabled               = true
  multi_volume_snapshotting_enabled = true
  silent_mode_enabled               = true
  validation_enabled                = false

  retention = {
    after_backup = false
    rules = [
      {
        max_count = 7
      }
    ]
  }

  scheduling = {
    enabled              = true
    max_parallel_backups = 0
    random_max_delay     = "5m"
    scheme               = "ALWAYS_INCREMENTAL"
    weekly_backup_day    = "MONDAY"
    backup_sets = [
      {
        backup_set_type     = "TYPE_AUTO"
        type                = "DAILY"
        execute_by_interval = 86400
      },
    ]
  }
}

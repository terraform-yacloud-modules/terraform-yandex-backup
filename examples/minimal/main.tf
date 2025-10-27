data "yandex_client_config" "client" {}

module "network" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git?ref=v1.0.0"

  folder_id  = data.yandex_client_config.client.folder_id
  blank_name = "instance-minimal-vpc-nat-gateway"

  azs = ["ru-central1-a"]

  private_subnets    = [["10.18.0.0/24"]]
  create_vpc         = true
  create_nat_gateway = true
}

module "yandex_compute_instance" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-instance.git?ref=v1.0.0"

  folder_id = data.yandex_client_config.client.folder_id

  name = "instance"

  zone       = "ru-central1-a"
  subnet_id  = module.network.private_subnets_ids[0]
  enable_nat = true
  create_pip = true

  hostname         = "instance"
  generate_ssh_key = false
  ssh_user         = "ubuntu"
  ssh_pubkey       = "~/.ssh/id_rsa.pub"

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


module "iam_accounts" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account?ref=v1.0.0"

  name = "iam"
  folder_roles = [
    "editor",
  ]
  cloud_roles              = []
  enable_static_access_key = false
  enable_api_key           = false
  enable_account_key       = false

}

module "daily_backup_policy" {
  # Путь к папке с файлами модуля
  source = "../.."

  # Обязательные параметры
  name = "my-daily-backup-policy"


  # Привязка политики к ВМ
  create_policy_binding = true

  policy_binding_instance_id = module.yandex_compute_instance.instance_id

  archive_name                      = "[Machine Name]-[Plan ID]-[Unique ID]a"
  cbt                               = "DO_NOT_USE"
  compression                       = "NORMAL"
  fast_backup_enabled               = true
  format                            = "AUTO"
  multi_volume_snapshotting_enabled = true
  performance_window_enabled        = false
  silent_mode_enabled               = true
  splitting_bytes                   = "9223372036854775807"
  vss_provider                      = "NATIVE"

  # Параметры повторных попыток
  reattempts = {
    enabled      = true
    interval     = "5m"
    max_attempts = 5
  }

  # Параметры расписания
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

  # Параметры хранения
  retention = {
    after_backup = true
    rules = [
      {
        # Хранить копии, сделанные за последние 14 дней
        max_age = "14d"
      }
    ]
  }

  # Параметры повторных попыток снапшотов ВМ
  vm_snapshot_reattempts = {
    enabled      = true
    interval     = "5m"
    max_attempts = 5
  }

  # Фильтры файлов
  file_filters = {
    inclusion_masks = ["/var/www/**", "/etc/nginx/**"]
    exclusion_masks = ["*.log", "*.tmp"]
  }

  # Дополнительные параметры

  sector_by_sector   = false
  validation_enabled = true

  lvm_snapshotting_enabled = true
}

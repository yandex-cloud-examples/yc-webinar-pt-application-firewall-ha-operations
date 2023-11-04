terraform {
  required_version = ">= 0.14"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.60"
    }
  }
}

provider "yandex" {
  token = var.token
  #or you can use: service_account_key_file = var.token for sa account 
  cloud_id = var.cloud_id
  folder_id = var.folder_id
}
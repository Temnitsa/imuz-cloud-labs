terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

# Мы будем передавать токен отдельно при запуске
variable "yc_token" {
  type = string
  description = "Yandex Cloud OAuth Token"
}

locals {
  # Твой ID каталога (взято из твоих логов)
  folder_id = "b1g100kk55n7ma74fei1"
}

provider "yandex" {
  token     = var.yc_token
  folder_id = local.folder_id
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "vm-1" {
  name = "imuz-yandex-bot"
  platform_id = "standard-v1" 

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80bm0rh4rkepi5ksdi" # Ubuntu 20.04
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    # Путь к ключу на сервере, где запустим Terraform
    ssh-keys = "ubuntu:${file("/home/ubuntu/.ssh/id_rsa_deploy.pub")}"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "imuz-network"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "imuz-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

output "external_ip" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

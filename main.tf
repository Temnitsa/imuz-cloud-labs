terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

variable "yc_token" {
  type = string
  description = "Yandex Cloud OAuth Token"
}

locals {
  folder_id = "b1g100kk55n7ma74fei1"
}

provider "yandex" {
  token     = var.yc_token
  folder_id = local.folder_id
  zone      = "ru-central1-a"
}

# --- СЕРВЕР ---
resource "yandex_compute_instance" "vm-1" {
  name = "imuz-yandex-bot-pipeline"
  platform_id = "standard-v1" 

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80bm0rh4rkepi5ksdi"
    }
  }

  network_interface {
    # ВСТАВЛЯЕМ ID ТВОЕЙ СУЩЕСТВУЮЩЕЙ ПОДСЕТИ (imuz-subnet)
    subnet_id = "e9b9uce0pt6elo5ksbrp"
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("/home/ubuntu/.ssh/id_rsa_deploy.pub")}"
  }
}

output "external_ip" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

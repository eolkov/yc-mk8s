# Variables

variable "token" {
  type = string
  description = "Yandex Cloud API key"
}

variable "cloud-id" {
  type = string
  description = "Yandex Cloud id"
}

variable "folder-id" {
  type = string
  description = "Yandex Cloud folder id"
}

# Provider

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud-id
  folder_id = var.folder-id
}

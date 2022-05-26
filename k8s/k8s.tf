# yandex_kubernetes_cluster

resource "yandex_kubernetes_cluster" "zonal_k8s_cluster" {
  name        = "my-cluster"
  description = "my-cluster description"
  network_id = yandex_vpc_network.network-1.id

  master {
    version = "1.21"
    zonal {
      zone      = yandex_vpc_subnet.subnet-1.zone
      subnet_id = yandex_vpc_subnet.subnet-1.id
    }
    public_ip = true
  }

  service_account_id      = yandex_iam_service_account.this.id
  node_service_account_id = yandex_iam_service_account.this.id
  release_channel = "STABLE"
  network_policy_provider = "CALICO"
  depends_on = [yandex_resourcemanager_folder_iam_binding.editor]
}

# yandex_kubernetes_node_group

resource "yandex_kubernetes_node_group" "k8s_node_group" {
  cluster_id  = yandex_kubernetes_cluster.zonal_k8s_cluster.id
  name        = "name"
  description = "description"
  version     = "1.21"

  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = [yandex_vpc_subnet.subnet-1.id]
    }

    resources {
      memory = 8
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 50
    }

    scheduling_policy {
      preemptible = false
    }
    
    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }
    
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "15:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "10:00"
      duration   = "4h30m"
    }
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "kuber-network"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name       = "subnet1"
  zone       = "ru-central1-a"
  network_id = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["10.2.0.0/16"]
}


locals {
  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${yandex_kubernetes_cluster.zonal_k8s_cluster.master[0].external_v4_endpoint}
    certificate-authority-data: ${base64encode(yandex_kubernetes_cluster.zonal_k8s_cluster.master[0].cluster_ca_certificate)}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: yc
  name: ycmk8s
current-context: ycmk8s
users:
- name: yc
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: yc
      args:
      - k8s
      - create-token
KUBECONFIG
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}

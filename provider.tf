terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.0.2"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.0.2"
    }
    null = {
      source = "hashicorp/null"
      version = "3.1.0"
    }
    kind = {
      source = "unicell/kind"
      version = "0.0.2-u2"
    }
  }
}

provider "kubernetes" {
  config_path = kind_cluster.vault-consul.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = kind_cluster.vault-consul.kubeconfig_path
  }
}

provider "null" {}
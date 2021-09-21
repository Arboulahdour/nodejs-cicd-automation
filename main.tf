terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}
provider "kubernetes" {
  host = "https://192.168.39.130:8443"
#  config_path = false
  client_certificate = file("/var/lib/jenkins/workspace/nodejs-deploy-k8s/.minikube/profiles/minikube/client.crt")
  client_key = file("/var/lib/jenkins/workspace/nodejs-deploy-k8s/.minikube/profiles/minikube/client.key")
  cluster_ca_certificate = file("/var/lib/jenkins/workspace/nodejs-deploy-k8s/.minikube/ca.crt")	
}

resource "kubernetes_deployment" "product-dep" {
  metadata {
    name = "product-dep"
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "product"
      }
    }
    template {
      metadata {
        labels = {
          app = "product"
        }
      }
      spec {
        container {
          image = "arboulahdour/nodejs-product:1.0.0"
          name  = "product-container"
          port {
            container_port = 3000
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "product-svc" {
  metadata {
    name = "product-svc"
  }
  spec {
    selector = {
      app = "product"
    }
    type = "NodePort"
    port {
      node_port   = 30000
      port        = 8000
      target_port = 3000
    }
  }
}

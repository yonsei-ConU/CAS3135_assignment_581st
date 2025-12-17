terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
  required_version = ">= 1.5.0"
}

provider "kubernetes" {
  config_path = var.kubernetes_config_path
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = "calc"
  }
}

data "aws_ecr_authorization_token" "ecr_token" {
}

resource "kubernetes_secret" "aws_ecr_cred" {
  metadata {
    name      = "aws-ecr-cred"
    namespace = kubernetes_namespace.ns.metadata[0].name # Ensures namespace exists first
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${data.aws_ecr_authorization_token.ecr_token.proxy_endpoint}" = {
          username = data.aws_ecr_authorization_token.ecr_token.user_name
          password = data.aws_ecr_authorization_token.ecr_token.password
          auth     = data.aws_ecr_authorization_token.ecr_token.authorization_token
        }
      }
    })
  }
}
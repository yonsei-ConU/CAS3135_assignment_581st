terraform {
    backend "s3" {
        bucket         = "cas3135-2025-tfstates"
        key            = "cas3135-2024148081/calc-k8s"
        dynamodb_table = "cas3135-terraform-locks"
        region         = "ap-northeast-2"
        encrypt        = true
    }
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

resource "kubernetes_config_map" "backend-config" {
  metadata {
		name = "backend-config"
		namespace = "calc"
	}
	data = {
		FRONTEND_URL = var.frontend_url
	}
}

resource "kubernetes_deployment" "backend" {
	metadata {
		name = "backend"
		namespace = "calc"
	}
	spec {
		selector {
			match_labels = {
				run = "calc-backend"
			}
		}
		replicas = 1
		template{
			metadata {
				labels = {
					run = "calc-backend"
				}
			}
			spec {
				image_pull_secrets {
      				name = "aws-ecr-cred"
    			}
				container {
					name = "backend"
					image = var.container_image_be
					image_pull_policy = "Always"
					env_from {
						config_map_ref {
							name = "backend-config"
						}
					}
				}
			}
		}
	}
}

resource "kubernetes_service" "backend" {
	metadata {
		name = "backend"
		namespace = "calc"
	}
	spec {
		type = "NodePort"
		selector = {
			run = "calc-backend"
		}
		port {
			port = 3031
			node_port = 30031
		}
	}
}
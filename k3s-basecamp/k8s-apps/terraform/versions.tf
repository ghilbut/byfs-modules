terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    mysql = {
      source = "terraform-providers/mysql"
    }
    null = {
      source = "hashicorp/null"
    }
    random = {
      source = "hashicorp/random"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}

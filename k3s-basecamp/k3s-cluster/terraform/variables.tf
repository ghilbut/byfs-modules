variable aws_region {
  type = string
}

variable aws_ami {
  type = string
}

variable vpc_id {
  type = string
}

variable subnet_id {
  type = string
}

variable private_key_name {
  type = string
}

variable private_key_path {
  type = string
}

variable domain_name {
  type = string
}

variable tags {
  type = map(string)
}

variable cluster_name {
  type = string
}

variable kubeconfig_path {
  type = string
}

variable argo_admin_password {
  type = string
}

variable argo_github_client_id {
  type = string
}

variable argo_github_client_secret {
  type = string
}

variable argo_github_org {
  type = string
}

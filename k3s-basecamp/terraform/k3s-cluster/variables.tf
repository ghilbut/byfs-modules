variable aws_region {
  type = string
}

variable aws_ami {
  type = string
}

variable public_key_name {
  type = string
}

variable public_key_path {
  type = string
}

variable domain_name {
  type = string
}

variable tags {
  type = map(string)
}

variable kubeconfig {
  type = string
}

variable argoconfig {
  type = string
}

variable argo_github_client_id {
  type = string
}

variable argo_github_client_secret {
  type = string
}

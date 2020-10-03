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

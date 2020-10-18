variable domain_name {
  type = string
}

variable kubeconfig_path {
  type = string
}

variable helmchart_url {
  type = string
}

variable helmchart_rev {
  type = string
}

variable ingress_ip {
  type = string
}

variable mysq_host {
  type = string
}

variable mysql_port {
  type = number
}

variable github_orgs {
  type = list(string)
}

/*
variable ebs_cp_zookeeper_ids {
  type = list(string)
}

variable ebs_cp_kafka_ids {
  type = list(string)
}
*/

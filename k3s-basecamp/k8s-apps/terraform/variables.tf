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

variable mysql_host {
  type = string
}

variable mysql_port {
  type = number
}

variable github_clients {
  type = map(object({ id=string, secret=string }))
}

variable github_orgs {
  type = list(string)
  default = []
}              

variable drone_repository_filter {
  type = string
}

variable ebs_influxdb_id {
  type = string
}

variable ebs_influxdb_size {
  type = number
}

/*
variable ebs_cp_zookeeper_ids {
  type = list(string)
}

variable ebs_cp_kafka_ids {
  type = list(string)
}
*/

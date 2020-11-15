variable aws_region {
  type = string
}

variable aws_s3_endpoint {
  type = string
}


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

variable github_org {
  type = string
}


########################################################################
##
##  Variables for applications
##

##----------------------------------------------------------------------
##  Argo CD

variable argo_github_client {
  type = object({ id = string, secret = string })
}

variable argo_admin_password {
  type = string
}

##----------------------------------------------------------------------
##  Dashboard

variable dashboard_github_client {
  type = object({ id = string, secret = string })
}

##----------------------------------------------------------------------
##  Docker-Registry

variable docker_github_client {
  type = object({ id = string, secret = string })
}

variable docker_registry_s3_bucket {
  type = string
}

variable docker_registry_access_key {
  type = string
}

variable docker_registry_secret_key {
  type = string
}

##----------------------------------------------------------------------
##  Drone CI

variable drone_github_client {
  type = object({ id = string, secret = string })
}

variable drone_github_personal_token {
  type = string
}

variable drone_mysql_password {
  type = string
}

variable drone_repository_filter {
  type = string
}

##----------------------------------------------------------------------
##  Elasticsearch

variable elasticsearch_ebs_volume {
  type = object({ id = string, size = number })
}

##----------------------------------------------------------------------
##  Grafana

variable grafana_github_client {
  type = object({ id = string, secret = string })
}

variable grafana_admin_password {
  type = string
}

variable grafana_mysql_password {
  type = string
}

##----------------------------------------------------------------------
##  InfluxDB

variable influxdb_ebs_volume {
  type = object({ id = string, size = number })
}

variable influxdb_admin_password {
  type = string
}

variable influxdb_user_password {
  type = string
}

variable influxdb_reader_password {
  type = string
}

variable influxdb_writer_password {
  type = string
}

##----------------------------------------------------------------------
##  Kafka

variable zookeeper_ebs_volumes {
  type = object({
    data = object({ id = string, size = number })
    log  = object({ id = string, size = number })
  })
}

variable kafka_ebs_volume {
  type = object({ id = string, size = number })
}

variable kafka_github_client {
  type = object({ id = string, secret = string })
}

##----------------------------------------------------------------------
##  Kibana

variable kibana_github_client {
  type = object({ id = string, secret = string })
}

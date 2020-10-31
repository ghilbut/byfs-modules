variable aws_region {
  type = string
}

variable tags {
  type = map(string)
}

variable mysql_name {
  type = string
  default = "byfs-k3s-basecamp"
}

variable mysql_instance {
  type = string
  default = "db.t2.micro"
}

variable ebs_zookeeper_data_size {
  type = number
  default = 1
}

variable ebs_zookeeper_log_size {
  type = number
  default = 4
}

variable ebs_kafka_data_size {
  type = number
  default = 500
}

variable ebs_influxdb_data_size {
  type = number
  default = 16
}

variable unique_name {
  type = string
}

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

##--------------------------------------------------------------
##  Elasticsearch

variable ebs_elasticsearch_data_size {
  type = number
  default = 256
}

##--------------------------------------------------------------
##  InfluxDB

variable ebs_influxdb_data_size {
  type = number
  default = 16
}

##--------------------------------------------------------------
##  Kafka

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

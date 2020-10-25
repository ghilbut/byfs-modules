variable aws_region {
  type = string
}

variable mysql_name {
  type = string
  default = "byfs-k3s-basecamp"
}

variable mysql_instance {
  type = string
  default = "db.t2.micro"
}

variable ebs_influxdb_size {
  type = number
  default = 8
}

variable tags {
  type = map(string)
}

variable aws_region {
  type = string
}

variable mysql_name {
  type = string
}

variable mysql_instance {
  type = string
  default = "db.t2.micro"
}

variable tags {
  type = map(string)
}

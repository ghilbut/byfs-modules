variable aws_profile {
  type = string
}

variable aws_region {
  type = string
}

variable tags {
  type = map
}

variable unique_name {
  type = string
}

variable root_domain {
  type = string
}

variable alb_public_domains {
  type = list(string)
}

variable alb_private_domains {
  type = list(string)
}

variable cluster_name {
  type = string
}

variable mysql_name {
  type = string
}

variable mysql_instance {
  type = string
}
variable unique_name {
  type = string
}

variable aws_profile {
  type    = string
}

variable aws_region {
  type    = string
}

variable tags {
  type    = map(string)
  default = {}
}

##--------------------------------------------------------------
##  VPC

variable vpc {
  type = object({
    id = string
  })
  description = "AWS VPC came from byfs-common"
}

##--------------------------------------------------------------
##  MySQL

variable mysql_instance {
  type = string
  description = "AWS RDS MySQL instance type"
}

variable mysql_database {
  type = string
  description = "AWS RDS MySQL default database name"
}

##--------------------------------------------------------------
##  AWS ECS cluster

variable ecs_cluster {
  type = object({
    id   = string
    name = string
  })
  description = "AWS ECS cluster"
}

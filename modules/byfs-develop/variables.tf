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
##  AWS ECS cluster

variable ecs_cluster {
  type = object({
    id   = string
    name = string
  })
  description = "AWS ECS cluster"
}



##--------------------------------------------------------------
##  MySQL

variable mysql {
  type = object({
    host = string
    port = number
    username = string
    password = string
  })
}

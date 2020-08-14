variable aws_region {
  type    = string
}

variable aws_profile {
  type    = string
}

variable prefix {
  type = string
}

variable tags {
  type    = map(string)
  default = {}
}

##--------------------------------------------------------------
##  Domain

variable domain_root {
  type        = string
  description = "Root domain name"
}

variable domain_name {
  type        = string
  description = "Service domain name"
}


################################################################
##
##  byfs:common
##

##--------------------------------------------------------------
##  MySQL

variable mysql_host {
  type = object({
    arn   = string
    value = string
  })
  description = "MySQL address"
}

variable mysql_port {
  type = object({
    arn   = string
    value = string
  })
  description = "MySQL port"
}

variable mysql_database {
  type = object({
    arn   = string
    value = string
  })
  description = "MySQL database name"
}

variable mysql_username {
  type = object({
    arn   = string
    value = string
  })
  description = "MySQL username"
}

variable mysql_password {
  type = object({
    arn   = string
    value = string
  })
  description = "MySQL password"
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
##  Django

variable django_max_capacity {
  type    = number
  default = 1
}

variable django_min_capacity {
  type    = number
  default = 1
}

variable django_scale_out_cpu_high {
  type        = number
  default     = 80
  description = "CPU hight threshold percent for scale-out"
}

variable django_scale_in_cpu_low {
  type    = number
  default = 30
  description = "CPU low threshold percent for scale-in"
}

##--------------------------------------------------------------
##  Vue.js


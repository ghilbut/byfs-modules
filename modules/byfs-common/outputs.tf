output vpc {
  value = {
    id = data.aws_vpc.default.id
  }
  description = "AWS VPC"
}

output subnet_public {
  value = data.aws_subnet.defaults.*.id
  description = "AWS VPC Subnets for DMZ Zone"
}

output security_group_private {
  value = {
    id = aws_security_group.private.id
    arn = aws_security_group.private.arn
  }
  description = "AWS Security Group to deny public inbound"
}

output security_group_public {
  value = {
    id = aws_security_group.public.id
    arn = aws_security_group.public.arn
  }
  description = "AWS Security Group to allow public inbound"
}

output alb_private {
  value = {
    arn = aws_lb.alb_private.arn
    dns_name = aws_lb.alb_private.dns_name
    zone_id = aws_lb.alb_private.zone_id
  }
  description = "AWS Application Load Balancer to deny public inbound"
}

output alb_public {
  value = {
    arn = aws_lb.alb_public.arn
    dns_name = aws_lb.alb_public.dns_name
    zone_id = aws_lb.alb_public.zone_id
  }
  description = "AWS Application Load Balancer to allow public inbound"
}

output alb_listener_private {
  value = {
    arn = aws_lb_listener.http_private.arn
  }
  description = "AWS Application Load Balancer Listener for private network"
}

output alb_listener_public {
  value = {
    arn = aws_lb_listener.https_public.arn
  }
  description = "AWS Application Load Balancer Listener for public network"
}

output ecs_cluster {
  value = {
    id   = aws_ecs_cluster.byfs.id
    name = aws_ecs_cluster.byfs.name
  }
  description = "AWS ECS Fargate cluster"
}

output ecs_task_execution_role {
  value = {
    arn = aws_iam_role.ecs_task_execution.arn
    name = aws_iam_role.ecs_task_execution.name
  }
  description = "IAM role for ECS task execution"
}

output mysql_host {
  value = {
    arn   = aws_secretsmanager_secret.mysql_host.arn
    value = aws_db_instance.mysql.address
  }
  description = "MySQL address"
  sensitive   = true
}

output mysql_port {
  value = {
    arn   = aws_secretsmanager_secret.mysql_port.arn
    value = aws_db_instance.mysql.port
  }
  description = "MySQL port"
  sensitive   = true
}

output mysql_database {
  value = {
    arn   = aws_secretsmanager_secret.mysql_database.arn
    value = random_string.mysql_database.result
  }
  description = "MySQL database name"
  sensitive   = true
}

output mysql_username {
  value = {
    arn   = aws_secretsmanager_secret.mysql_username.arn
    value = random_string.mysql_username.result
  }
  description = "MySQL admin username"
  sensitive   = true
}

output mysql_password {
  value = {
    arn   = aws_secretsmanager_secret.mysql_password.arn
    value = random_password.mysql_password.result
  }
  description = "MySQL admin password"
  sensitive   = true
}
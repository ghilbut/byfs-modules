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

output ecs_cluster {
  value = {
    id   = aws_ecs_cluster.byfs.id
    name = aws_ecs_cluster.byfs.name
  }
  description = "AWS ECS Fargate cluster Id"
}

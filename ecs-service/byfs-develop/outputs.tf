output mysql_host {
  value = var.mysql.host
}

output mysql_port {
  value = var.mysql.port
}

output mysql_database {
  value = terraform.workspace
}

output mysql_username {
  value = terraform.workspace
}

output mysql_password_secret {
  value = {
    arn = aws_secretsmanager_secret.mysql_password.arn
    value = random_password.mysql_password.result
  }
  sensitive = true
}

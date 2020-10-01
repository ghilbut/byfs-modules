output mysql_host {
  value = aws_db_instance.mysql.address
}

output mysql_port {
  value = aws_db_instance.mysql.port
}

output mysql_database {
  value = var.mysql_database
}

output mysql_username_secret {
  value = {
    arn = aws_secretsmanager_secret.mysql_username.arn
    value = random_string.mysql_username.result
  }
}

output mysql_password_secret {
  value = {
    arn = aws_secretsmanager_secret.mysql_password.arn
    value = random_password.mysql_password.result
  }
}

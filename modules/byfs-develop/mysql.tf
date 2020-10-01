################################################################
##
##  MySQL logical database
##

provider mysql {
  endpoint = "${var.mysql.host}:${var.mysql.port}"
  username = var.mysql.username
  password = var.mysql.password
}

##--------------------------------------------------------------
##  password

resource aws_secretsmanager_secret mysql_password {
  name = "byfs-${var.unique_name}-${terraform.workspace}-mysql-password"
  recovery_window_in_days = 0
}

resource random_password mysql_password {
  length           = 12
  override_special = "!@#$%^&*()"
}

resource aws_secretsmanager_secret_version mysql_password {
  secret_id     = aws_secretsmanager_secret.mysql_password.id
  secret_string = random_password.mysql_password.result
}

##--------------------------------------------------------------
##  database

resource mysql_database default {
  default_character_set = "utf8mb4"
  default_collation     = "utf8mb4_unicode_ci"
  name                  = terraform.workspace
}

resource mysql_user default {
  user               = terraform.workspace
  host               = "%"
  plaintext_password = random_password.mysql_password.result
}

resource mysql_grant default {
  user       = mysql_user.default.user
  host       = mysql_user.default.host
  database   = mysql_database.default.name
  privileges = ["ALL"]
}
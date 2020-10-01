################################################################
##
##  MySQL 5.7
##

locals {
  mysql_name = "${var.unique_name}-mysql-production"
  mysql_database = "production"
}

##--------------------------------------------------------------
##  aws security group for mysql

resource aws_security_group mysql {
  name        = local.mysql_name
  description = "Allow MySQL traffic for production"
  vpc_id      = var.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",  # TODO(ghilbut): remove
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0",  # TODO(ghilbut): remove
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  tags = merge(
    map(
      "Name", "sg-${local.mysql_name}",
    ),
    local.tags,
  )
}

##--------------------------------------------------------------
##  Parameter Group

resource aws_db_parameter_group mysql {
  name   = local.mysql_name
  family = "mysql5.7"

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  tags = merge(
    map(
      "Name",  "pg-${local.mysql_name}",
    ),
    local.tags, 
  )
}

##--------------------------------------------------------------
##  MySQL

resource random_string mysql_username {
  length  = 8
  upper   = false
  number  = false
  special = false
}

resource random_password mysql_password {
  length = 12
  # [2020/04/04] Error creating DB Instance: InvalidParameterValue: The parameter MasterUserPassword is not a valid password. Only printable ASCII characters besides '/', '@', '"', ' ' may be used.
  special = false
  override_special = "!@#$%^&*()"
}

resource aws_db_instance mysql {
  allocated_storage     = 20
  availability_zone     = "ap-northeast-2a"
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = var.mysql_instance
  name                  = local.mysql_database
  username              = random_string.mysql_username.result
  password              = random_password.mysql_password.result
  parameter_group_name  = aws_db_parameter_group.mysql.id

  identifier = "rds-${local.mysql_name}"

  skip_final_snapshot = true
  publicly_accessible = true

  vpc_security_group_ids = [
    aws_security_group.mysql.id,
  ]

  tags = merge(
    map(
      "Name", "rds-${local.mysql_name}",
    ),
    local.tags, 
  )
}



################################################################
##
##  AWS Secret Manager
##

##--------------------------------------------------------------
##  username

resource aws_secretsmanager_secret mysql_username {
  name = "${local.mysql_name}-username"
  recovery_window_in_days = 0
}

resource aws_secretsmanager_secret_version mysql_username {
  secret_id     = aws_secretsmanager_secret.mysql_username.id
  secret_string = random_string.mysql_username.result
}

##--------------------------------------------------------------
##  password

resource aws_secretsmanager_secret mysql_password {
  name = "${local.mysql_name}-password"
  recovery_window_in_days = 0
}

resource aws_secretsmanager_secret_version mysql_password {
  secret_id     = aws_secretsmanager_secret.mysql_password.id
  secret_string = random_password.mysql_password.result
}
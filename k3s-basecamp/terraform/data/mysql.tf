/*
################################################################
##
##  MySQL 5.7
##

##--------------------------------------------------------------
##  Security Group

resource aws_security_group mysql {
  name = var.mysql_name
  description = "Allow MySQL inbound traffic"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks = local.private_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks = local.private_cidrs
  }

  tags = merge(
    {
      Name = "sg-${var.mysql_name}"
    },
    local.tags, 
  )
}

##--------------------------------------------------------------
##  Parameter Group

resource aws_db_parameter_group mysql {
  name   = var.mysql_name
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
    {
      Name = "pg-${var.mysql_name}"
    },
    local.tags, 
  )
}

##--------------------------------------------------------------
##  MySQL

resource random_string mysql_database {
  length  = 8
  upper   = false
  number  = false
  special = false
}

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
  allocated_storage     = 8
  availability_zone     = "${var.aws_region}a"
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = var.mysql_instance
  max_allocated_storage = 1024
  name                  = random_string.mysql_database.result
  username              = random_string.mysql_username.result
  password              = random_password.mysql_password.result
  parameter_group_name  = aws_db_parameter_group.mysql.id

  identifier = "rds-${var.mysql_name}"

  skip_final_snapshot = true
  publicly_accessible = true

  vpc_security_group_ids = [
    aws_security_group.mysql.id,
  ]

  tags = merge(
    {
      Name = "rds-${var.mysql_name}",
    },
    local.tags, 
  )
}



################################################################
##
##  AWS Secret Manager
##

##--------------------------------------------------------------
##  password

resource aws_secretsmanager_secret mysql_password {
  name = "${var.mysql_name}-password"
  recovery_window_in_days = 0
}

resource aws_secretsmanager_secret_version mysql_password {
  secret_id     = aws_secretsmanager_secret.mysql_password.id
  secret_string = random_password.mysql_password.result
}
*/

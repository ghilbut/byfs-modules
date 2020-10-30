################################################################
##
##  Common Database
##

output mysql_host {
  value = aws_db_instance.mysql.address
}

output mysql_port {
  value = aws_db_instance.mysql.port
}

output mysql_database {
  value = random_string.mysql_database.result
}

output mysql_username {
  value = random_string.mysql_username.result
  sensitive = true
}

output mysql_password {
  value = random_password.mysql_password.result
  sensitive = true
}

output mysql_password_secret {
  value = {
    arn = aws_secretsmanager_secret.mysql_password.arn
    id  = aws_secretsmanager_secret.mysql_password.id
  }
  sensitive = true
}


################################################################
##
##  For Applications
##

##--------------------------------------------------------------
##  Argo CD

output argo_admin_password {
  value = random_password.argo_admin.result
  sensitive = true
}

##--------------------------------------------------------------
##  Drone CI

output drone_mysql_password {
  value = random_password.drone_mysql.result
  sensitive = true
}

##--------------------------------------------------------------
##  Grafana

output grafana_mysql_password {
  value = random_password.grafana_mysql.result
  sensitive = true
}

output grafana_admin_password {
  value = random_password.grafana_admin.result
  sensitive = true
}

##--------------------------------------------------------------
##  InfluxDB

output influxdb_ebs_volume {
  value = {
    id = aws_ebs_volume.influxdb.id
    size = var.ebs_influxdb_data_size
  }
}

output influxdb_admin_password {
  value = random_password.influxdb_admin.result
  sensitive = true
}

output influxdb_user_password {
  value = random_password.influxdb_user.result
  sensitive = true
}

output influxdb_reader_password {
  value = random_password.influxdb_reader.result
  sensitive = true
}

output influxdb_writer_password {
  value = random_password.influxdb_writer.result
  sensitive = true
}

##--------------------------------------------------------------
##  Kafka

output zookeeper_ebs_volumes {
  value = {
    data = {
      id = aws_ebs_volume.zookeeper.id
      size = var.ebs_zookeeper_data_size
    }
    log = {
      id = aws_ebs_volume.zookeeper_log.id
      size = var.ebs_zookeeper_log_size
    }
  }
}

output kafka_ebs_volume {
  value = {
    id = aws_ebs_volume.kafka.id
    size = var.ebs_kafka_data_size
  }
}

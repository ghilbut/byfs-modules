##--------------------------------------------------------------
##  Argo CD

resource random_password argo_admin {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()"
}

##--------------------------------------------------------------
##  Drone CI

resource random_password drone_mysql {
  length           = 16
  special          = true
  override_special = "‘~!@#$%^&*()_-+={}[]/<>,.;?':|"
}

##--------------------------------------------------------------
##  Grafana

resource random_password grafana_mysql {
  length           = 16
  special          = true
  override_special = "‘~!@#$%^&*()_-+={}[]/<>,.;?':|"
}

resource random_password grafana_admin {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()"
}

##--------------------------------------------------------------
##  InfluxDB

resource random_password influxdb_admin {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-"
}

resource random_password influxdb_user {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-"
}

resource random_password influxdb_reader {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-"
}

resource random_password influxdb_writer {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-"
}

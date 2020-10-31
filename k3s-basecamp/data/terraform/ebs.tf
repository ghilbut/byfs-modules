locals {
  az = "${var.aws_region}a"
}

resource aws_ebs_volume zookeeper {
  availability_zone = local.az
  size = var.ebs_zookeeper_data_size

  tags = merge({
    Name = "ebs-basecamp-zookeeper"
  }, local.tags)
}

resource aws_ebs_volume zookeeper_log {
  availability_zone = local.az
  size = var.ebs_zookeeper_log_size

  tags = merge({
    Name = "ebs-basecamp-zookeeper-log"
  }, local.tags)
}

resource aws_ebs_volume kafka {
  availability_zone = local.az
  size = var.ebs_kafka_data_size
  type = "st1"

  tags = merge({
    Name = "ebs-basecamp-kafka"
  }, local.tags)
}

resource aws_ebs_volume influxdb {
  availability_zone = local.az
  size = var.ebs_influxdb_data_size

  tags = merge({
    Name = "ebs-basecamp-influxdb"
  }, local.tags)
}

resource aws_ebs_volume vpn {
  availability_zone = local.az
  size = 1

  tags = merge({
    Name = "ebs-basecamp-vpn"
  }, local.tags)
}



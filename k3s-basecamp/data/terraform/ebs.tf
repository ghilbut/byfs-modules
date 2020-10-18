locals {
  az = "${var.aws_region}a"
}

resource aws_ebs_volume cp_zookeeper {
  count = 3

  availability_zone = local.az
  size              = 2

  tags = merge({
    Name = "ebs-cp-zookeeper-${count.index}"
  }, local.tags)
}

resource aws_ebs_volume cp_kafka {
  count = 3

  availability_zone = local.az
  size              = 10

  tags = merge({
    Name = "ebs-cp-kafka-${count.index}"
  }, local.tags)
}

resource aws_ebs_volume vpn {
  availability_zone = local.az
  size              = 1

  tags = merge({
    Name = "ebs-basecamp-vpn"
  }, local.tags)
}

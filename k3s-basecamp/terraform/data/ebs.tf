locals {
  az = "${var.aws_region}a"
}

resource aws_ebs_volume vpn {
  availability_zone = local.az
  size              = 1

  tags = merge({
    Name = "ebs-basecamp-vpn"
  }, local.tags)
}

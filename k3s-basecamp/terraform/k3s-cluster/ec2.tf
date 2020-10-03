data aws_vpc default {
  default = true
}

data aws_subnet default {
  availability_zone = "${var.aws_region}a"
  default_for_az = true
  vpc_id = data.aws_vpc.default.id
}

resource aws_security_group private {
  name        = "basecamp-private"
  description = "Allow all inbound traffic from private IPs"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "private"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.private_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.private_cidrs
  }

  tags = merge({
    Name = "sg-basecamp-private"
  }, local.tags)
}

resource aws_security_group public {
  name        = "basecamp-public"
  description = "Allow all inbound traffic from public IPs"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "public"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "sg-basecamp-public"
  }, local.tags)
}

resource aws_instance basecamp {
  ami                                  = var.aws_ami
  associate_public_ip_address          = true
  availability_zone                    = "${var.aws_region}a"
  ebs_optimized                        = true
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "m5.large"
  key_name                             = var.public_key_name
  root_block_device {
    delete_on_termination = true
    volume_type = "gp2"
    volume_size = 80
  }
  subnet_id                            = data.aws_subnet.default.id
  vpc_security_group_ids               = [
    aws_security_group.private.id,
    aws_security_group.public.id,
  ]

  tags = merge({
    Name = "basecamp"
  }, local.tags)
}

data aws_route53_zone private {
  name         = var.domain_name
  private_zone = true
}

data aws_route53_zone public {
  name         = var.domain_name
  private_zone = false
}

resource aws_route53_record wildcard_private {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "*.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.basecamp.private_ip]
}

resource aws_route53_record wildcard_public {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "*.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.basecamp.public_ip]
}

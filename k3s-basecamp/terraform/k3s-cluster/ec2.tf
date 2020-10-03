################################################################
##
##  EC2
##

resource aws_instance basecamp {
  ami                                  = var.aws_ami
  associate_public_ip_address          = true
  availability_zone                    = "${var.aws_region}a"
  ebs_optimized                        = true
  iam_instance_profile                 = aws_iam_instance_profile.basecamp.name
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
    Name = "ec2-k3s-basecamp"
  }, local.tags)
}


################################################################
##
##  IAM
##

resource aws_iam_instance_profile basecamp {
  name = "k3s-basecamp"
  role = aws_iam_role.basecamp.name
}

resource aws_iam_role basecamp {
  name               = "k3s-basecamp"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF

  tags = merge({
    Name = "iam-k3s-basecamp-role"
  }, local.tags)
}

resource aws_iam_role_policy ebs_access {
  name   = "k3s-basecamp"
  role   = aws_iam_role.basecamp.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:ModifyInstanceAttribute",
          "ec2:ModifyVolume",
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeVpcs"
        ],
        "Effect": "Allow",
        "Resource": ["*"]
      }
    ]
  }
  EOF
}


################################################################
##
##  Route53
##

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


################################################################
##
##  VPC
##

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

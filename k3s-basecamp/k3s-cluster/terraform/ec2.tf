################################################################
##
##  EC2
##

resource aws_instance master {
  ami                                  = var.aws_ami
  associate_public_ip_address          = true
  availability_zone                    = "${var.aws_region}a"
  ebs_optimized                        = true
  iam_instance_profile                 = aws_iam_instance_profile.basecamp.name
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "r5.xlarge"
  key_name                             = var.private_key_name
  root_block_device {
    delete_on_termination = true
    volume_type = "gp2"
    volume_size = 80
  }
  subnet_id                            = var.subnet_id
  vpc_security_group_ids               = [
    aws_security_group.private.id,
    aws_security_group.public.id,
  ]

  tags = merge({
    Name = "ec2-k3s-basecamp"
    KubernetesCluster = var.cluster_name
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

resource aws_iam_role_policy ebs {
  name   = "k3s-basecamp-ebs"
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

resource aws_iam_role_policy route53 {
  name   = "k3s-basecamp-route53"
  role   = aws_iam_role.basecamp.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "route53:GetChange",
        "Effect": "Allow",
        "Resource": "arn:aws:route53:::change/*"
      },
      {
        "Action": [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Effect": "Allow",
        "Resource": "arn:aws:route53:::hostedzone/*"
      },
      {
        "Action": "route53:ListHostedZonesByName",
        "Effect": "Allow",
        "Resource": "*"
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
  records = [aws_instance.master.private_ip]
}

resource aws_route53_record wildcard_public {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "*.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.master.public_ip]
}


################################################################
##
##  VPC
##

resource aws_security_group private {
  name        = "basecamp-private"
  description = "Allow all inbound traffic from private IPs"
  vpc_id      = var.vpc_id

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
    KubernetesCluster = var.cluster_name
  }, local.tags)
}

resource aws_security_group public {
  name        = "basecamp-public"
  description = "Allow all inbound traffic from public IPs"
  vpc_id      = var.vpc_id

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
    KubernetesCluster = var.cluster_name
  }, local.tags)
}

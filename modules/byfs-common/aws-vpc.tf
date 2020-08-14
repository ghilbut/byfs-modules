################################################################
##
##  AWS VPC network
##

data aws_vpc default {
  default = true
}

data aws_subnet defaults {
  count = length(local.az_suffixes)

  availability_zone = "${var.aws_region}${local.az_suffixes[count.index]}"
  default_for_az = true
  vpc_id = data.aws_vpc.default.id
}

data aws_subnet default {
  availability_zone = "${var.aws_region}a"
  default_for_az = true
  vpc_id = data.aws_vpc.default.id
}


################################################################
##
##  AWS Security Groups
##

##--------------------------------------------------------------
##  aws security group for private

resource aws_security_group private {
  name        = "${var.unique_name}-private"
  description = "Allow all traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
    ipv6_cidr_blocks = ["fd00::/8"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = merge(
    map(
      "Name", "sg-${var.unique_name}-private",
    ),
    local.tags,
  )
}

##--------------------------------------------------------------
##  aws security group for public

resource aws_security_group public {
  name        = "${var.unique_name}-public"
  description = "Allow all traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = merge(
    map(
      "Name", "sg-${var.unique_name}-public",
    ),
    local.tags,
  )
}
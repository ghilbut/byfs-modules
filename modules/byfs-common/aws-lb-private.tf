################################################################
##
##  AWS LB Private
##

data aws_route53_zone private {
  name         = var.root_domain
  private_zone = true
}

##--------------------------------------------------------------
##  aws security group for private

resource aws_security_group alb_private {
  name        = "${var.unique_name}-alb-private"
  description = "Allow all traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
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
      "Name", "sg-${var.unique_name}-alb-private",
    ),
    local.tags,
  )
}

##--------------------------------------------------------------
##  aws application load balancer

resource aws_lb alb_private {
  name               = "alb-${var.unique_name}-private"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_private.id]
  subnets            = data.aws_subnet.defaults.*.id

  tags = merge(
  map(
  "Name",  "alb-${var.unique_name}",
  ),
  local.tags,
  )
}

resource aws_lb_listener http_private {
  load_balancer_arn = aws_lb.alb_private.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found (AWS Application Load Balancer)"
      status_code  = "404"
    }
  }
}
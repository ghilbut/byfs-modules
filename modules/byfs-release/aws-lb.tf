################################################################
##
##  AWS VPC
##

resource aws_security_group web {
  name        = "${var.prefix}-web"
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
      "Name", "sg-${var.prefix}-web",
    ),
    local.tags, 
  )
}



################################################################
##
##  AWS LB
##

resource aws_lb alb {
  name               = "alb-${var.prefix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = data.aws_subnet.defaults.*.id

  tags = merge(
    map(
      "Name",  "alb-${var.prefix}",
    ),
    local.tags, 
  )
}

resource aws_lb_listener http {
  load_balancer_arn = aws_lb.alb.arn
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

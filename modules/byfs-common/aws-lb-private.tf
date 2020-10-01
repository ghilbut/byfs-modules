################################################################
##
##  AWS Application Load Balancer for private
##

data aws_route53_zone private {
  name         = var.root_domain
  private_zone = true
}

##--------------------------------------------------------------
##  aws application load balancer

resource aws_lb alb_private {
  name               = "alb-${var.unique_name}-private"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private.id]
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


################################################################
##
##  AWS Network Load Balancer for private
##

resource aws_lb nlb_private {
  name               = "nlb-${var.unique_name}-private"
  internal           = true
  load_balancer_type = "network"
  subnets            = data.aws_subnet.defaults.*.id

  enable_deletion_protection = false

  tags = merge(
    map(
      "Name", "nlb-${var.unique_name}-private",
    ),
    local.tags,
  )
}

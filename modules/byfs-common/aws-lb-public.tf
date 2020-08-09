################################################################
##
##  AWS LB Public
##

data aws_route53_zone public {
  name         = var.root_domain
  private_zone = false
}

##--------------------------------------------------------------
##  aws certificate manager for public

resource aws_acm_certificate alb_public {
  #provider = aws.acm_certificate

  domain_name               = var.alb_public_domains[0]
  subject_alternative_names = slice(var.alb_public_domains, 1, length(var.alb_public_domains))
  validation_method         = "DNS"

  tags = merge(
    map(
      "Name", "${var.unique_name}-acm-certificate-public",
    ),
    local.tags,
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_route53_record aws_acm_certificate_alb_public {
  for_each = {
    for opt in aws_acm_certificate.alb_public.domain_validation_options : opt.domain_name => {
      name   = opt.resource_record_name
      record = opt.resource_record_value
      type   = opt.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.public.zone_id
}

resource aws_acm_certificate_validation alb_public {
  certificate_arn         = aws_acm_certificate.alb_public.arn
  validation_record_fqdns = [for record in aws_route53_record.aws_acm_certificate_alb_public : record.fqdn]
}

##--------------------------------------------------------------
##  aws security group for public

resource aws_security_group alb_public {
  name        = "${var.unique_name}-alb-public"
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
      "Name", "sg-${var.unique_name}-alb-public",
    ),
    local.tags,
  )
}

##--------------------------------------------------------------
##  aws application load balancer

resource aws_lb alb_public {
  name               = "alb-${var.unique_name}-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_public.id]
  subnets            = data.aws_subnet.defaults.*.id

  tags = merge(
  map(
  "Name",  "alb-${var.unique_name}",
  ),
  local.tags,
  )
}

resource aws_lb_listener http_public {
  load_balancer_arn = aws_lb.alb_public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource aws_lb_listener https_public {
  depends_on = [
    aws_route53_record.aws_acm_certificate_alb_public,
  ]

  load_balancer_arn = aws_lb.alb_public.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.alb_public.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found (AWS Application Load Balancer)"
      status_code  = "404"
    }
  }
}
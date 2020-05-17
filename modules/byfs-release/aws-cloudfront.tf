################################################################
##
##  AWS Certificate Manager
##

resource aws_acm_certificate web {
  provider = aws.acm_certificate

  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(
    map(
      "Name", var.domain_name,
    ),
    local.tags,
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_route53_record aws_acm_certificate_web {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = aws_acm_certificate.web.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.web.domain_validation_options.0.resource_record_type
  ttl     = 5

  records = [
    aws_acm_certificate.web.domain_validation_options.0.resource_record_value,
  ]
}



################################################################
##
##  AWS CloudFront
##

resource aws_cloudfront_origin_access_identity web {
  comment = var.domain_name
}

resource aws_cloudfront_distribution web {
  depends_on = [
    aws_route53_record.aws_acm_certificate_web,
  ]

  origin {
    domain_name = aws_s3_bucket.web.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.web.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = aws_lb.alb.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [
    var.domain_name,
  ]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.web.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0  # 3600
    max_ttl                = 0  # 86400
  }

  ordered_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    default_ttl     = 0

    forwarded_values {
      cookies {
        forward = "all"
      }
      headers      = ["*"]
      query_string = true
    }

    max_ttl         = 0
    min_ttl         = 0
    path_pattern    = "/admin*"
    target_origin_id = aws_lb.alb.dns_name
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    default_ttl     = 0

    forwarded_values {
      cookies {
        forward = "all"
      }
      headers      = ["*"]
      query_string = true
    }

    max_ttl         = 0
    min_ttl         = 0
    path_pattern    = "/api*"
    target_origin_id = aws_lb.alb.dns_name
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    default_ttl     = 0

    forwarded_values {
      cookies {
        forward = "all"
      }
      headers      = ["*"]
      query_string = true
    }

    max_ttl         = 0
    min_ttl         = 0
    path_pattern    = "/swagger*"
    target_origin_id = aws_lb.alb.dns_name
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    default_ttl     = 0

    forwarded_values {
      cookies {
        forward = "all"
      }
      headers      = ["*"]
      query_string = true
    }

    max_ttl         = 0
    min_ttl         = 0
    path_pattern    = "/redoc*"
    target_origin_id = aws_lb.alb.dns_name
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["KR"]
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.web.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2018"
    ssl_support_method             = "sni-only"
  }
}



################################################################
##
##  AWS Route 53
##

resource aws_route53_record cloudfront {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.web.domain_name
    zone_id                = aws_cloudfront_distribution.web.hosted_zone_id
    evaluate_target_health = true
  }
} 

################################################################
##
##  AWS S3
##

##--------------------------------------------------------------
##  AWS Security Groups

resource aws_s3_bucket web {
  bucket        = var.domain_name
  acl           = "private"
  force_destroy = true

  tags = merge(
    map(
      "Name",  var.domain_name,
    ),
    local.tags,
  )
}

resource aws_s3_bucket_policy web {
  bucket = aws_s3_bucket.web.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "cloudfront-only",
  "Statement": [
    {
      "Action":   ["s3:ListBucket"],
      "Effect":   "Allow",
      "Resource": ["${aws_s3_bucket.web.arn}"],
      "Principal": {
        "AWS": [
          "${aws_cloudfront_origin_access_identity.web.iam_arn}"
        ]
      }
    },
    {
      "Action":   ["s3:GetObject"],
      "Effect":   "Allow",
      "Resource": ["${aws_s3_bucket.web.arn}/*"],
      "Principal": {
        "AWS": [
          "${aws_cloudfront_origin_access_identity.web.iam_arn}"
        ]
      }
    }
  ]
}
EOF
}

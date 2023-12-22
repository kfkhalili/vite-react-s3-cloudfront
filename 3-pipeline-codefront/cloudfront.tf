resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac_${var.app_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  description                       = "OAC for ${var.app_name}"
}

resource "aws_cloudfront_distribution" "frontend_distribution" {
  is_ipv6_enabled = true

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    domain_name              = aws_s3_bucket.app_static.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.app_static.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.app_static.bucket_domain_name
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6" # ID for "CachingOptimized"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  ordered_cache_behavior {
    path_pattern     = "/"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.app_static.bucket_domain_name
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6" # ID for "CachingOptimized"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
}

output "domain_name" {
  description = "This is the Domain Name of the created CloudFront Distribution"
  value = aws_cloudfront_distribution.frontend_distribution.domain_name
}
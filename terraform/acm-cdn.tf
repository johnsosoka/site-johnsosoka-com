// CloudFront distribution for 'www'. This is where CloudFront retrieves its content.
resource "aws_cloudfront_distribution" "www_distribution" {
  default_root_object = "index.html"

  // Specify a "custom" origin to redirect traffic from root domain (johnsosoka.com) to www.johnsosoka.com.
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    // The URL of our S3 bucket is used as the domain name.
    domain_name = aws_s3_bucket_website_configuration.www_website_configuration.website_endpoint
    origin_id   = local.www_domain_name
  }

  enabled = true

  // The default cache behavior, with standard values from AWS console.
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.www_domain_name
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  // Ensuring that this distribution is accessible via www.johnsosoka.com.
  aliases = [local.www_domain_name]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  // SSL certificate details.
  viewer_certificate {
    acm_certificate_arn = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert
    ssl_support_method  = "sni-only"
  }
}

// CloudFront distribution for 'root' follows the same pattern as 'www'.
resource "aws_cloudfront_distribution" "root_distribution" {
  default_root_object = "index.html"

  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = aws_s3_bucket_website_configuration.root_website_configuration.website_endpoint
    origin_id   = local.root_domain_name
  }

  enabled = true

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.root_domain_name
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = [local.root_domain_name]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert
    ssl_support_method  = "sni-only"
  }
}

// CloudFront distribution for 'stage' follows the same pattern as 'www'.
resource "aws_cloudfront_distribution" "stage_distribution" {
  default_root_object = "index.html"

  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = aws_s3_bucket_website_configuration.stage_website_configuration.website_endpoint
    origin_id   = local.stage_domain_name
  }

  enabled = true

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.stage_domain_name
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = [local.stage_domain_name]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert
    ssl_support_method  = "sni-only"
  }
}

// Media

resource "aws_cloudfront_distribution" "media_distribution" {
  default_root_object = "index.html"

  // Specify a "custom" origin to redirect traffic from root domain (johnsosoka.com) to media.johnsosoka.com.
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    // The URL of our S3 bucket is used as the domain name.
    domain_name = aws_s3_bucket_website_configuration.media_website_configuration.website_endpoint
    origin_id   = local.media_domain_name
  }

  enabled = true

  // The default cache behavior, with standard values from AWS console.
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.media_domain_name
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  // Ensuring that this distribution is accessible via media.johnsosoka.com.
  aliases = [local.media_domain_name]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  // SSL certificate details.
  viewer_certificate {
    acm_certificate_arn = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert
    ssl_support_method  = "sni-only"
  }
}

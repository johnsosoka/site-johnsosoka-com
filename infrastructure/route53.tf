// We want AWS to host our zone so its nameservers can point to our CloudFront
// distribution.
resource "aws_route53_zone" "zone" {
  name = "${local.root_domain_name}"
}

// This Route53 record will point to our CloudFront distributions which in turn point to s3.
resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.zone.zone_id}"
  name    = "${local.www_domain_name}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.www_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.www_distribution.hosted_zone_id}"
    evaluate_target_health = false // living dangerously.
  }
}

resource "aws_route53_record" "root" {
  zone_id = "${aws_route53_zone.zone.zone_id}"

  name = ""
  type = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.root_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.root_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

// files subdomain set up here.
resource "aws_route53_record" "files_subdomain" {
  zone_id = "${aws_route53_zone.zone.zone_id}"

  name = "${local.files_fqdn}"
  type = "A"


  alias {
    name                   = "${aws_cloudfront_distribution.files_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.files_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

// api subdomain setup below (move to different repo)

resource "aws_api_gateway_domain_name" "api_domain" {
  domain_name              = "${local.api_fqdn}"
  regional_certificate_arn = aws_acm_certificate.certificate.arn
  # The valid values are TLS_1_0 and TLS_1_2
  security_policy = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "api_gateway_dns" {
  name    = aws_api_gateway_domain_name.api_domain.domain_name
  type    = "A"
  zone_id = aws_route53_zone.zone.id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api_domain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api_domain.regional_zone_id
  }
}
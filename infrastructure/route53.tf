// We want AWS to host our zone so its nameservers can point to our CloudFront
// distribution.

// This Route53 record will point to our CloudFront distributions which in turn point to s3.
resource "aws_route53_record" "www" {
  zone_id = data.terraform_remote_state.jscom_common_data.outputs.root_johnsosokacom_zone_id
  name    = local.www_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.www_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.www_distribution.hosted_zone_id
    evaluate_target_health = false // living dangerously.
  }
}

resource "aws_route53_record" "root" {
  zone_id = data.terraform_remote_state.jscom_common_data.outputs.root_johnsosokacom_zone_id

  name = ""
  type = "A"

  alias {
    name                   = aws_cloudfront_distribution.root_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.root_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

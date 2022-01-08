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

// Minecraft subdomain set up here.
resource "aws_route53_record" "minecraft" {
  zone_id = "${aws_route53_zone.zone.zone_id}"

  name = "${local.minecraft_subdomain_name}"
  type = "A"

  ttl = "5"
  records = ["${var.minecraft_target_ip}"]
}
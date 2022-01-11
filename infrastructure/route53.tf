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

// MAIL
resource "aws_route53_record" "zoho_mail_route" {
  name = ""
  type = "MX"
  zone_id = aws_route53_zone.zone.zone_id
  ttl = "5"
  records = ["10 mx.zoho.com",
             "20 mx2.zoho.com",
             "50 mx3.zoho.com"]

}

resource "aws_route53_record" "zoho_mail_spf" {
  name = ""
  type = "TXT"
  zone_id = aws_route53_zone.zone.zone_id
  ttl = "5"
  records = [var.zoho_domain_spf]

}

resource "aws_route53_record" "zoho_mail_domain_key" {
  name = "zmail._domainkey"
  type = "TXT"
  zone_id = aws_route53_zone.zone.zone_id
  ttl = "5"
  records = ["${var.zoho_domain_key}"]

}

// END MAIL
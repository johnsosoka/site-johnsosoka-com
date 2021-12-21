# output variables for shared variables / cross project reference.
output "jscom_acm_cert" {
  value = aws_acm_certificate.certificate.arn
}

output "root_johnsosokacom_zone_id" {
  value = aws_route53_zone.zone.zone_id
}
# custom domain & key..


# what else?
# output variables for shared variables / cross project reference.
output "jscom_acm_cert" {
  value = aws_acm_certificate.certificate.arn
}

output "root_johnsosokacom_zone_id" {
  value = aws_route53_zone.zone.zone_id
}

# mail from arn
output "no_reply_mail_ses_id" {
  value = aws_ses_email_identity.no_reply.arn
}
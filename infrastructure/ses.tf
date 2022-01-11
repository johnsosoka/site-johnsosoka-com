resource "aws_ses_email_identity" "no_reply" {
  email = var.no_reply_send_address
}
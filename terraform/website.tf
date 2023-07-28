// Creates all websites defined in the websites variable
module "website" {
  for_each = var.websites
  source = "git::https://github.com/johnsosoka/jscom-tf-modules.git//modules/static-website?ref=main"
  domain_name = each.value
  root_zone_id = local.root_zone_id
  acm_cert_id = local.acm_cert_id
}

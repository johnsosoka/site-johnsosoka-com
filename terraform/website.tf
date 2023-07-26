module "stage_website" {
  source = "git::https://github.com/johnsosoka/jscom-core-infrastructure.git//modules/static-website?ref=static-site-module"
  domain_name = var.stage_domain_name
  root_zone_id = data.terraform_remote_state.jscom_common_data.outputs.root_johnsosokacom_zone_id
  acm_cert_id = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert
}

module "www_website" {
  source = "git::https://github.com/johnsosoka/jscom-core-infrastructure.git//modules/static-website?ref=static-site-module"
  domain_name = var.www_domain_name
  root_zone_id = data.terraform_remote_state.jscom_common_data.outputs.root_johnsosokacom_zone_id
  acm_cert_id = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert
}

module "root_website" {
  source = "git::https://github.com/johnsosoka/jscom-core-infrastructure.git//modules/static-website?ref=static-site-module"
  domain_name = var.www_domain_name
  root_zone_id = data.terraform_remote_state.jscom_common_data.outputs.root_johnsosokacom_zone_id
  acm_cert_id = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert
}

module "media_website" {
  source = "git::https://github.com/johnsosoka/jscom-core-infrastructure.git//modules/static-website?ref=static-site-module"
  domain_name = var.media_domain_name
  root_zone_id = data.terraform_remote_state.jscom_common_data.outputs.root_johnsosokacom_zone_id
  acm_cert_id = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert
}
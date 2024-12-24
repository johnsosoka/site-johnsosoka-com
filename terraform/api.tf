module "api" {
  source                  = "git::https://github.com/johnsosoka/jscom-tf-modules.git//modules/base-api?ref=main"
  api_gateway_name        = "jscom-api"
  api_gateway_description = "services for johnsosoka.com"
  custom_domain_name      = "api.johnsosoka.com"
  domain_certificate_arn  = local.acm_cert_regional
  route53_zone_id         = local.root_zone_id

  tags = {
    Environment = "prod"
    Project     = "jscom web"
  }
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = module.api.api_gateway_id
}

output "api_gateway_execution_arn" {
  description = "Default endpoint of the API Gateway"
  value       = module.api.api_gateway_execution_arn
}

output "custom_domain_name" {
  description = "Custom domain name for the API Gateway"
  value       = module.api.custom_domain_name
}

output "custom_domain_name_target" {
  description = "Target domain name for the Route53 alias"
  value       = module.api.custom_domain_name_target
}

output "custom_domain_hosted_zone_id" {
  description = "Hosted Zone ID for the custom domain"
  value       = module.api.custom_domain_hosted_zone_id
}
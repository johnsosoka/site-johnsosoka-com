variable "project_name" {
  default = "jscom-blog"
}

// All the static sites to create
variable "websites" {
  type = map(string)
  default = {
    "stage" = "stage.johnsosoka.com",
    "www"   = "www.johnsosoka.com",
    "root"  = "johnsosoka.com"
  }
  description = "The websites to create"
}

locals {
  deployer_user_name = "github-deployer-user"
  root_zone_id = data.terraform_remote_state.jscom_common_data.outputs.root_johnsosokacom_zone_id
  acm_cert_id = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert_global
}

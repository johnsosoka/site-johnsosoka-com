provider "aws" {
  region = "us-west-2"
}

// Terraform state managed remotely.
terraform {
  backend "s3" {
    // WARNING  -- Couldn't read from variables.tf in this block!!
    bucket         = "johnsosoka-com-tf-backend"
    key            = "project/jscom-blog/state/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state"
  }
}
// Defining some values that will be utilized throughout.
locals {

  // johnsosoka.com
  root_domain_name = "${var.domain_name}.${var.domain}"
  // www.johnsosoka.com
  www_domain_name = "www.${local.root_domain_name}"
  // files.johnsosoka.com
  files_fqdn = "${var.files_subdomain}.${local.root_domain_name}"

  // minecraft.johnsosoka.com
  minecraft_subdomain_name = "${var.minecraft_subdomain}.${local.root_domain_name}"

}

data "terraform_remote_state" "jscom_common_data" {
  backend = "s3"
  config = {
    bucket = "johnsosoka-com-tf-backend"
    key = "project/jscom-core-infra/state/terraform.tfstate"
    region = "us-west-2"
  }
}

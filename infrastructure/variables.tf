variable "project_name" {
  default = "johnsosoka.com-blog"
}

// WWW and Root

variable "domain_name" {
  type = string
  default = "johnsosoka"
  description = "My websites domain name"
}

variable "domain" {
  type = string
  default = "com"
  description = "The domain my site belongs to"
}

// Subdomains Below

variable "files_subdomain" {
  default = "files"
  description = "Files subdomain...for logically partitioning site data stores. Download files separate from blog content."
}


variable "minecraft_subdomain" {
  type = string
  default = "minecraft"
}
variable "minecraft_target_ip" {
  type = string
  default = "135.148.29.129"
}

// End Subdomains

// mailing

variable "zoho_mail_record" {
  type = string
  default = "zmverify.zoho.com"
}

variable "zoho_domain_key" {
  type = string
  default = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCmq7d9ORJKWOi881Yy2EaIizIXFbxVq4R7Q7NK+AOUMub78L5W5fmtsWz9BFG5mNCJ8BvcZqYF5MRsA9YsyDA1mGximIFcGPlo4DGvUq370UCA3mlES3VRYldRQrax6wyQ0rcF0GuDYTCmc4odsD8qq9F3HhZGzZOJ4XHJP7dmKwIDAQAB"
}

variable "zoho_domain_spf" {
  type = string
  default = "v=spf1 include:zoho.com ~all"
}
// Additional Resource Naming:

// logs bucket name
variable "logs_bucket_name" {
  default = "johnsosoka-com-logs"
  description = "bucket name for logging bucket."
}

variable "www_johnsosoka_logs_path" {
  default = "logs/johnsosoka-com-www/"
  description = "The path for saving www access logs on the logging bucket."
}

variable "terraform_backend_bucket_name" {
  default = "johnsosoka-com-tf-backend"
  description = "Terraform backend bucket name."
}
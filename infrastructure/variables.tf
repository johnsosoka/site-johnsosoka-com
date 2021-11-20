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

// End Subdomains

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
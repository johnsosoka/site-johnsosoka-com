variable "project_name" {
  default = "jscom-blog"
}

// WWW and Root

variable "stage_domain_name" {
  type = string
  default = "stage.johnsosoka.com"
  description = "My websites domain name"
}

variable "www_domain_name" {
  type = string
  default = "www.johnsosoka.com"
  description = "My websites domain name"
}

variable "root_domain_name" {
  type = string
  default = "johnsosoka.com"
  description = "My websites domain name"
}

variable "media_domain_name" {
  type = string
  default = "media.johnsosoka.com"
  description = "My websites domain name"
}
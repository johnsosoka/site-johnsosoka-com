variable "project_name" {
  default = "jscom-blog"
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

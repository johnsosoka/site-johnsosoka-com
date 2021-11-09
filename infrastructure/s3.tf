// S3 buckets for johnsosoka.com.
//  johnsosoka.com bucket redirects to www.johnsosoka.com, which hosts the blog posts.
//  file bucket is for logically separating hosted content (minecraft world downloads, music, etc)
//  from blog/website files.

resource "aws_s3_bucket" "www" {
  // bucket name will match site name.
  bucket = local.www_domain_name
  acl    = "public-read"
  // We also need to create a policy that allows anyone to view the content.
  // This is basically duplicating what we did in the ACL but it's required by
  // AWS. This post: http://amzn.to/2Fa04ul explains why.
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${local.www_domain_name}/*"]
    }
  ]
}
POLICY

  // Set up Logging
  logging {
    target_bucket = aws_s3_bucket.www_log_bucket.id
    target_prefix = var.www_johnsosoka_logs_path
  }
  // Tell S3 it's purpose.
  website {
    // Here we tell S3 what to use when a request comes in to the root
    // ex. https://www.johnsosoka.com/index.html
    index_document = "index.html"
    // The page to serve up if a request results in an error or a non-existing
    // page.
    error_document = "404.html"
  }
}

// Root S3 bucket here (johnsosoka.com). This S3 bucket will redirect to www

resource "aws_s3_bucket" "root" {
  bucket = "${local.root_domain_name}"
  acl    = "public-read"
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${local.root_domain_name}/*"]
    }
  ]
}
POLICY

  website {
    // Note this redirect. Here's where the magic happens.
    redirect_all_requests_to = "https://${local.www_domain_name}"
  }
}


resource "aws_s3_bucket" "file_share" {
  bucket = local.files_fqdn
  acl    = "public-read"
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${local.files_fqdn}/*"]
    }
  ]
}
POLICY

  website {
    // For now these will break, but index.html could be a file tree or something in the future.
    index_document = "index.html"
    error_document = "404.html"
  }
}

// LOGGING BUCKET
resource "aws_s3_bucket" "www_log_bucket" {

  bucket = var.logs_bucket_name
  acl    = "log-delivery-write"

  lifecycle_rule {
    id      = "log"
    enabled = true

    prefix = "log/"

    tags = {
      rule      = "log"
      autoclean = "true"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA" # or "ONEZONE_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    }
  }

}

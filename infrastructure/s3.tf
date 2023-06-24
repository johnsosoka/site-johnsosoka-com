// S3 buckets for johnsosoka.com.
//  johnsosoka.com bucket redirects to www.johnsosoka.com, which hosts the blog posts.
//  file bucket is for logically separating hosted content (minecraft world downloads, music, etc)
//  from blog/website files.
resource "aws_s3_bucket" "www" {
  // Our bucket's name is going to be the same as our site's domain name.
  bucket = local.www_domain_name
  // Because we want our site to be available on the internet, we set this so
  // anyone can read this bucket.
  // We also need to create a policy that allows anyone to view the content.
  // This is basically duplicating what we did in the ACL but it's required by
  // AWS. This post: http://amzn.to/2Fa04ul explains why.
}

resource "aws_s3_bucket_policy" "www_policy" {
  bucket = aws_s3_bucket.www.id
  policy = <<EOF
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
EOF
}

resource "aws_s3_bucket_acl" "acl_www" {
  bucket = aws_s3_bucket.www.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.www.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

// Root S3 bucket here (example.com). This S3 bucket will redirect to www

resource "aws_s3_bucket" "root" {
  bucket = local.root_domain_name

}

resource "aws_s3_bucket_website_configuration" "root_website_configuration" {
  bucket = aws_s3_bucket.root.id

  // Note this redirect. Here's where the magic happens.
  redirect_all_requests_to {
    host_name = local.www_domain_name
    protocol = "https"

  }

}

resource "aws_s3_bucket_policy" "root_policy" {
  bucket = aws_s3_bucket.root.id
  policy = <<EOF
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
EOF
}

resource "aws_s3_bucket_acl" "acl_root" {
  bucket = aws_s3_bucket.root.id
  acl    = "public-read"
}



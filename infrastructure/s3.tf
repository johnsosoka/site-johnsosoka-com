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
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AddPerm"
        Effect = "Allow"
        Principal = "*"
        Action = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::${aws_s3_bucket.www.bucket}/*"]
      }
    ]
  })
}

// enable bucket versioning
resource "aws_s3_bucket_versioning" "www_versioning" {
  bucket = aws_s3_bucket.www.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "www_ownership_controls" {
  bucket = aws_s3_bucket.www.id
  rule {
    # one of [BucketOwnerPreferred ObjectWriter BucketOwnerEnforced]
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "www_access_block" {
  bucket = aws_s3_bucket.www.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "acl_www" {
  depends_on = [
    aws_s3_bucket_ownership_controls.www_ownership_controls,
    aws_s3_bucket_public_access_block.www_access_block
  ]
  bucket = aws_s3_bucket.www.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "www_website_configuration" {
  bucket = aws_s3_bucket.www.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# ==============================================================================
# Root S3 bucket here (example.com). This S3 bucket will redirect to www
# ==============================================================================

resource "aws_s3_bucket" "root_web" {
  bucket = local.root_domain_name
}

resource "aws_s3_bucket_policy" "root_policy" {
  bucket = aws_s3_bucket.root_web.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AddPerm"
        Effect = "Allow"
        Principal = "*"
        Action = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::${aws_s3_bucket.root_web.bucket}/*"]
      }
    ]
  })
}

// enable bucket versioning
resource "aws_s3_bucket_versioning" "root_versioning" {
  bucket = aws_s3_bucket.root_web.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "root_ownership_controls" {
  bucket = aws_s3_bucket.root_web.id
  rule {
    # one of [BucketOwnerPreferred ObjectWriter BucketOwnerEnforced]
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "root_access_block" {
  bucket = aws_s3_bucket.root_web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "acl_root" {
  depends_on = [
    aws_s3_bucket_ownership_controls.root_ownership_controls,
    aws_s3_bucket_public_access_block.root_access_block
  ]
  bucket = aws_s3_bucket.root_web.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "root_website_configuration" {
  bucket = aws_s3_bucket.root_web.id

  redirect_all_requests_to {
    host_name = local.www_domain_name
    protocol = "https"
  }

#  index_document {
#    suffix = "index.html"
#  }
#
#  error_document {
#    key = "404.html"
#  }
}




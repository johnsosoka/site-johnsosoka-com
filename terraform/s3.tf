// ==============================================================================
// S3 buckets for johnsosoka.com.
// - johnsosoka.com bucket (root_web) redirects to www.johnsosoka.com (www), which hosts the blog posts.
// - The stage.johnsosoka.com bucket (stage) is used for staging content.
// ==============================================================================

// Primary bucket (www.johnsosoka.com)
resource "aws_s3_bucket" "www" {
  bucket = local.www_domain_name // Bucket's name is same as site's domain name.
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

// Enable bucket versioning for primary bucket
resource "aws_s3_bucket_versioning" "www_versioning" {
  bucket = aws_s3_bucket.www.id
  versioning_configuration {
    status = "Enabled"
  }
}

// Ownership controls for primary bucket
resource "aws_s3_bucket_ownership_controls" "www_ownership_controls" {
  bucket = aws_s3_bucket.www.id
  rule {
    object_ownership = "ObjectWriter" // one of [BucketOwnerPreferred ObjectWriter BucketOwnerEnforced]
  }
}

// Public access block settings for primary bucket
resource "aws_s3_bucket_public_access_block" "www_access_block" {
  bucket = aws_s3_bucket.www.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

// ACL settings for primary bucket
resource "aws_s3_bucket_acl" "acl_www" {
  depends_on = [
    aws_s3_bucket_ownership_controls.www_ownership_controls,
    aws_s3_bucket_public_access_block.www_access_block
  ]
  bucket = aws_s3_bucket.www.id
  acl    = "public-read"
}

// Website configuration for primary bucket
resource "aws_s3_bucket_website_configuration" "www_website_configuration" {
  bucket = aws_s3_bucket.www.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "404.html"
  }
}

// ==============================================================================
// Root bucket (johnsosoka.com)
// This bucket will redirect to the primary bucket (www)
// ==============================================================================

// Root bucket (johnsosoka.com)
resource "aws_s3_bucket" "root" {
  bucket = local.root_domain_name // Bucket's name is same as site's domain name.
}

resource "aws_s3_bucket_policy" "root_policy" {
  bucket = aws_s3_bucket.root.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AddPerm"
        Effect = "Allow"
        Principal = "*"
        Action = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::${aws_s3_bucket.root.bucket}/*"]
      }
    ]
  })
}

// Enable bucket versioning for root bucket
resource "aws_s3_bucket_versioning" "root_versioning" {
  bucket = aws_s3_bucket.root.id
  versioning_configuration {
    status = "Enabled"
  }
}

// Ownership controls for root bucket
resource "aws_s3_bucket_ownership_controls" "root_ownership_controls" {
  bucket = aws_s3_bucket.root.id
  rule {
    object_ownership = "ObjectWriter" // one of [BucketOwnerPreferred ObjectWriter BucketOwnerEnforced]
  }
}

// Public access block settings for root bucket
resource "aws_s3_bucket_public_access_block" "root_access_block" {
  bucket = aws_s3_bucket.root.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

// ACL settings for root bucket
resource "aws_s3_bucket_acl" "acl_root" {
  depends_on = [
    aws_s3_bucket_ownership_controls.root_ownership_controls,
    aws_s3_bucket_public_access_block.root_access_block
  ]
  bucket = aws_s3_bucket.root.id
  acl    = "public-read"
}

// Website configuration for root bucket
resource "aws_s3_bucket_website_configuration" "root_website_configuration" {
  bucket = aws_s3_bucket.root.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "404.html"
  }
}

// ==============================================================================
// Stage bucket (stage.johnsosoka.com)
// Repeat the same process for the stage bucket as we did for the primary bucket.
// ==============================================================================

// Stage bucket (stage.johnsosoka.com)
resource "aws_s3_bucket" "stage" {
  bucket = local.stage_domain_name // Bucket's name is same as site's domain name.
}

resource "aws_s3_bucket_policy" "stage_policy" {
  bucket = aws_s3_bucket.stage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AddPerm"
        Effect = "Allow"
        Principal = "*"
        Action = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::${aws_s3_bucket.stage.bucket}/*"]
      }
    ]
  })
}

// Enable bucket versioning for staging bucket
resource "aws_s3_bucket_versioning" "stage_versioning" {
  bucket = aws_s3_bucket.stage.id
  versioning_configuration {
    status = "Enabled"
  }
}

// Ownership controls for staging bucket
resource "aws_s3_bucket_ownership_controls" "stage_ownership_controls" {
  bucket = aws_s3_bucket.stage.id
  rule {
    object_ownership = "ObjectWriter" // one of [BucketOwnerPreferred ObjectWriter BucketOwnerEnforced]
  }
}

// Public access block settings for staging bucket
resource "aws_s3_bucket_public_access_block" "stage_access_block" {
  bucket = aws_s3_bucket.stage.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

// ACL settings for staging bucket
resource "aws_s3_bucket_acl" "acl_stage" {
  depends_on = [
    aws_s3_bucket_ownership_controls.stage_ownership_controls,
    aws_s3_bucket_public_access_block.stage_access_block
  ]
  bucket = aws_s3_bucket.stage.id
  acl    = "public-read"
}

// Website configuration for staging bucket
resource "aws_s3_bucket_website_configuration" "stage_website_configuration" {
  bucket = aws_s3_bucket.stage.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "404.html"
  }
}


// ==============================================================================
// Stage bucket (media.johnsosoka.com)
// Houses images for gallery and blog posts.
// ==============================================================================
resource "aws_s3_bucket" "media" {
  bucket = local.media_domain_name // Bucket's name is same as site's domain name.
}

resource "aws_s3_bucket_policy" "media_policy" {
  bucket = aws_s3_bucket.media.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AddPerm"
        Effect = "Allow"
        Principal = "*"
        Action = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::${aws_s3_bucket.media.bucket}/*"]
      }
    ]
  })
}

// Enable bucket versioning for media bucket
resource "aws_s3_bucket_versioning" "media_versioning" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration {
    status = "Enabled"
  }
}

// Ownership controls for media bucket
resource "aws_s3_bucket_ownership_controls" "media_ownership_controls" {
  bucket = aws_s3_bucket.media.id
  rule {
    object_ownership = "ObjectWriter" // one of [BucketOwnerPreferred ObjectWriter BucketOwnerEnforced]
  }
}

// Public access block settings for media bucket
resource "aws_s3_bucket_public_access_block" "media_access_block" {
  bucket = aws_s3_bucket.media.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

// ACL settings for media bucket
resource "aws_s3_bucket_acl" "acl_media" {
  depends_on = [
    aws_s3_bucket_ownership_controls.media_ownership_controls,
    aws_s3_bucket_public_access_block.media_access_block
  ]
  bucket = aws_s3_bucket.media.id
  acl    = "public-read"
}

// Website configuration for media bucket
resource "aws_s3_bucket_website_configuration" "media_website_configuration" {
  bucket = aws_s3_bucket.media.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "404.html"
  }
}
# Not organized by resource type, but instead organized by purpose.
# Candidate for moving into something like an infra-johnsosoka-com repo...

resource "aws_s3_bucket" "terraform-state" {
  bucket = var.terraform_backend_bucket_name
  acl = "private"

  versioning {
    enabled = true
  }
}

// Block public access!
resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.terraform-state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// DynamoDB lock table.
resource "aws_dynamodb_table" "terraform-state" {
  name           = "terraform-state"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

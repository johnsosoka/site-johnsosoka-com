resource "aws_iam_user" "deployer_user" {
  name = "github-deployer-user"
  path = "/system/"
}

resource "aws_iam_access_key" "deployer_user_access_key" {
  user = aws_iam_user.deployer_user.name
}

resource "aws_iam_user_policy" "deployer_user_policy" {
  name = "deployer-actions-policy"
  user = aws_iam_user.deployer_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::${module.www_website.website_bucket_id}/*",
        "arn:aws:s3:::${module.root_website.website_bucket_id}/*",
        "arn:aws:s3:::${module.stage_website.website_bucket_id}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "cloudfront:CreateInvalidation",
      "Resource": "*"
    }
  ]
}
EOF
}

output "github_deployer_user_access_key_id" {
  value = aws_iam_access_key.deployer_user_access_key.id
}

output "github_deployer_user_access_key_secret" {
  value = aws_iam_access_key.deployer_user_access_key.secret
  sensitive = true
}

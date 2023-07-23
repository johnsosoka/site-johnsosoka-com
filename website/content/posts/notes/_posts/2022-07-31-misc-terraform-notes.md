---
layout: post
category: note
title: Misc Terraform Notes
note_type: AWS Misc
---

## Recovering from Lost/Deleted Remote State

Initialize the backend & start working through errors from terraform-apply.

`bucket already exists`

```shell
terraform import aws_s3_bucket.bucket www.johnsosoka.com
```

**cloud front example**

```shell
terraform import aws_cloudfront_distribution.www_distribution <Distribution ID>
```

**dynamodb example**

```shell
terraform import aws_dynamodb_table.terraform-state terraform-state
```

## Reading a Hidden Terraform Variable

A terraform variable might be marked sensitive, such as:

```terraform
output "github_deployer_user_access_key_secret" {
  value = aws_iam_access_key.deployer_user_access_key.secret
  sensitive = true
}
```

To read this value, after running `terraform apply`, run:

```shell
terraform output -raw github_deployer_user_access_key_secret
```

This will print the value of the masked variable to the console.
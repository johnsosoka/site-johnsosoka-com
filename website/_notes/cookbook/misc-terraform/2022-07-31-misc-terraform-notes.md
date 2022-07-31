---
layout: note
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
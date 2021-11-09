# Infrastructure Setup

### Getting Started

1. Install **aws-cli**. Check out the [guide here](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html)
2. Configure aws-cli with `aws configure` (have a user provisioned on aws already)
3. Follow the [terraform installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli?)
4. Terraform should be able to execute on the johnsosoka-com account now.

## Infrastructure Overview
If you haven't figured it out by now--the infrastructure for this website is provisioned by terraform (with an AWS provider).

This is a static website, hosted on S3. AWS Requires multiple s3 buckets in order to have www.johnsosoka.com and johnsosoka.com. One redirects to the other.

I used [this guide](https://medium.com/runatlantis/hosting-our-static-site-over-ssl-with-s3-acm-cloudfront-and-terraform-513b799aec0f) as a template & starting point for _some_ the
infrastructure here, particularly around hosting the website itself.

#### Special Name Servers (manual step)
Terraform does not have support for [managing registered domains](https://github.com/hashicorp/terraform-provider-aws/issues/88) so once the hosted zone is generated you need to
fetch the name servers from it & update the "registered domain" in route53 to match

## Website Infrastructure Provisioned
The following is provisioned required for creating the static website itself.

### Two S3 Buckets for site
Two S3 buckets will be created for hosting the website along with their own cloud front distributions. johnsosoka.com redirects to www.johnsosoka.com which means s3://www.johnsosoka.com
is the primary s3 bucket, where the site contents will be stored.

### Additional S3 Bucket for File Hosting.
An additional s3 bucket as well as corresponding route53 records are created so that downloads that I host are
1. logically separated from the website content by having their own bucket
2. Pretty download urls, ex.)`http://files.johnsosoka.com/whatever/subject/content.zip`

## Backend Infrastructure Provisioned
Additional infrastructure has been provisioned here to assist with the running of other services besides hosting the blog. Some
include a Terraform backend (so that separate projects can reference each other's output variables)

### Terraform s3 Backend
A Terraform backend s3 server has been provisioned as part of the infrastructure scripts here. The intention is for
additional infrastructure not directly related to the blog to be hosted in its own topic or service based repository.

### DynamoDB Table Backend
ADynamoDB table is provisioned to serve as a lock table for the Terraform backend.

### Logging Bucket
A logging bucket is set up with naming abstract to host logs for more than blog access logs. Currently, the only
implementation is for housing access logs.

### API Gateway Domain Entry
In preparation for hosting some services to run johnsosoka.com this resource has been provisioned. Api routes can be attached
to api.johnsosoka.com (this happens discreetly in route53.tf)
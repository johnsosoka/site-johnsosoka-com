---
layout: post
title: Using Terraform to Provision AWS Infrastructure for an S3 Hosted Jekyll Blog
category: blog
subtitle: Building infrastructure for a personal site reproducibly & on the cheap.
tags: terraform s3 aws jekyll scripting awscli cloudfront route53
---

**Update 2023/07/23:**
- I've written an article on how to use GitHub Actions to automatically deploy this website. You can find it [here](/blog/2023/07/16/gitlab-pipeline-s3.html).

# Introduction

I first created this website last year, and I pieced it all together by hand using the aws console. Shortly after 
getting it running, I neglected to contribute to it. About a year later I found myself wanting to contribute to it with 
a more regular cadence, but had no idea how I had gotten it up and running in the first place. Rather than playing 
detective and uncovering my old steps, I decided to gut the whole thing and start over (of course.) 

This past year I have gotten a bit more exposure to HashiCorp's [Terraform](https://www.terraform.io/) and decided that 
this time around I would employ the paradigm of _infrastructure as code_ to provision the infrastructure required to run my 
website--this way, in the future I could just peak at my Terraform scripts to get an understanding of how I pieced it 
all together. 

For this post I am using & building off of the work from [this article](https://medium.com/runatlantis/hosting-our-static-site-over-ssl-with-s3-acm-cloudfront-and-terraform-513b799aec0f)
posted by runatlantis.io, so shout out to those folks for their work. Additionally, I address an issue the runatlantis 
team cited for migrating off of AWS with the aws-cli and a shell script at the end--creating a CloudFront Invalidation 
event upon deployment.


### Project Wish List

I have a small wish list for my project:

* Website Served over SSL (This will be accomplished with CloudFront and AWS Certificate Manager)
* A Subdomain for hosting downloads. https://files.johnsosoka.com is the target subdomain, this will point to its own
  S3 bucket, separate from the rest of the site.
* Both www.johnsosoka.com & johnsosoka.com to resolve (this requires 2 S3 buckets, one to redirect to the other)
* Easy to read & pick up later--If i abandon this again, I should be able to understand how it runs quickly.

### Requirements

To accomplish this, we will need properly configured tools. Terraform utilizes the [AWS CLI](https://aws.amazon.com/cli/) 
under the hood to identify the state of and provision resources.

#### Install AWS CLI

Installing the AWS CLI on linux is pretty straight forward. You can find a more up-to-date guide from amazon [here](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install)

Download the zip,
```commandline
# download
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# unzip
unzip awscliv2.zip

#install 
sudo ./aws/install
```

Verify the installation:

```commandline
aws --version
```

You should see the version returned & maybe a few other details. My output was:

```commandline
aws-cli/2.2.29 Python/3.8.8 Linux/5.11.0-34-generic exe/x86_64.ubuntu.20 prompt/off
```

Congrats, you have installed the aws-cli. Create an iam user which can be accessed with an access_key, this user will be
what terraform uses to provision resources on aws so be sure that it has relevant permissions.

Once your user is set up, issue the following command to configure:

```commandline
aws configure
```

#### Install Terraform

For up-to-date terraform installation instructions, check [the hashicorp website](https://learn.hashicorp.com/tutorials/terraform/install-cli)

1. ```shell
   sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
   ```
2. ```shell
   curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
   ```
3. ```shell
   sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
   ```
4. ```shell
   sudo apt-get update && sudo apt-get install terraform
   ```

Verify the installation by issuing the help command:

```shell
terraform -help
```

If the command resolves and you get some help text then you should be all set to proceed.

## Writing the Terraform Configuration.

I split my terraform configuration into multiple files to make this more approachable later when I inevitably start 
poking around to figure out how I set this up. I have grouped my configurations by resource or resources if they are 
closely related.

It is my understanding that under the hood, terraform will search for any `*.tf `and execute as though it's one giant 
file. You will see throughout that there are Terraform configurations which contain references in other files, despite 
no explicit import or reference to that file itself existing.

First up is `variables.tf`; In this file, I just define the basic building blocks of our website--the domain name & 
domain. These variables are later referenced in a locals block within `main.tf` where we create more complete variables
which are referenced throughout the configuration.

#### variables.tf
```terraform
variable "domain_name" {
  type = string
  default = "johnsosoka"
  description = "This is your sites domain name. DO NOT include the domain com|org|net|etc>"
}

variable "domain" {
  type = String
  default = "com"
  description = "This is the domain that your site belongs to <com|org|net|etc>"
}

variable "file_share_subdomain" {
  default = "files"
  description = "This is the file share subdomain name for your website. ex.) files.example.com"
}



```

Next up is `main.tf`, there isn't much to see here just a bit of housekeeping. We specify the terraform provider, this 
tells terraform that we're provisioning resources in AWS and not some alternative like GCP (Google Cloud Platform). 
Additionally, here we assemble some local variables from the vars in the previous file--Here we are basically generating
johnsosoka.com, www.johnsosoka.com & files.johnsosoka.com.

#### main.tf
```terraform
// This block tells Terraform that we're going to provision AWS resources.
provider "aws" {
  region = "us-east-1"
}

// Defining some values that will be utilized throughout.
locals {

  // ex.) example.com
  root_domain_name = "${var.domain_name}.${var.domain}"

  // ex.) www.example.com
  www_domain_name = "www.${local.root_domain_name}"

  // ex.) files.example.com
  file_share_domain_name = "${var.file_share_subdomain}.${local.root_domain_name}"
}
```

Working our way from where the content is served up, we will move on to the `s3.tf` file where we define the S3 buckets 
required to run the website. S3 is a file store provided by amazon, they have some bare-bones web-server functionality. 
In the following file, we provision 3 buckets.

| resource name | purpose |
|---------------|---------|
| www  | This bucket will host the static website assets generated by Jekyll. (www.johnsosoka.com) |
| root | Bucket will redirect root (johnsosoka.com) to www (www.johnsosoka.com) |
| file_share | Bucket will be separate from the website assets, this bucket will accomplish our wishlist item of "having a subdomain for hosting downloads" |


#### s3.tf
```terraform
// This is our first S3 Bucket and hosts our www domain, (www.example.com). It will host the site which will be static
// assets, generated by Jekyll.

resource "aws_s3_bucket" "www" {
  // Our bucket's name is going to be the same as our site's domain name.
  bucket = local.www_domain_name
  // Because we want our site to be available on the internet, we set this so
  // anyone can read this bucket.
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

  // S3 understands what it means to host a website.
  website {
    // Here we tell S3 what to use when a request comes in to the root
    // ex. https://www.example.com
    index_document = "index.html"
    // The page to serve up if a request results in an error or a non-existing
    // page.
    error_document = "404.html"
  }
}

// Root S3 bucket here (example.com). This S3 bucket will redirect to www

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
  bucket = local.file_share_domain_name
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
      "Resource":["arn:aws:s3:::${local.file_share_domain_name}/*"]
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
```

Now that our S3 buckets are created we need to configure CloudFront, which will be acting as our CDN. One of our wishlist 
items was to have our website served over SSL, so we are going to have a certificated created through amazon ACM & then 
use that certificate in our CloudFront distributions. Since these two actions were so closely linked, I decided to put 
them in a single configuration file.

#### acm-cdn.tf

```terraform
// Combining two related sets of resources.

// Use the AWS Certificate Manager to create an SSL cert for our domain.
// This resource won't be created until you receive the email verifying you
// own the domain and you click on the confirmation link.
resource "aws_acm_certificate" "certificate" {
  // We want a wildcard cert so we can host subdomains later.
  domain_name       = "*.${local.root_domain_name}"
  validation_method = "EMAIL"

  // We also want the cert to be valid for the root domain even though we'll be
  // redirecting to the www. domain immediately.
  subject_alternative_names = ["${local.root_domain_name}"]
}


// create cloudfront distributions which use the cert from above.


resource "aws_cloudfront_distribution" "www_distribution" {
  // origin is where CloudFront gets its content from.
  origin {
    // We need to set up a "custom" origin because otherwise CloudFront won't
    // redirect traffic from the root domain to the www domain, that is from
    // johnsosoka.com to www.johnsosoka.com
    custom_origin_config {
      // These are all the defaults.
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    // Here we're using our S3 bucket's URL!
    domain_name = "${aws_s3_bucket.www.website_endpoint}"
    // This can be any name to identify this origin.
    origin_id   = "${local.www_domain_name}"
  }

  enabled             = true
  // Removing default_root_object so that /index.html doesn't appear in browser bar
  //default_root_object = "index.html"

  // All values are defaults from the AWS console.
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    // This needs to match the `origin_id` above.
    target_origin_id       = "${local.www_domain_name}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  // Here we're ensuring we can hit this distribution with our nice DNs name rather than the domain name CloudFront 
  // gives us, (which would look something like http://d111111abcdef8.cloudfront.net) 
  // Details here: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-cloudfront-distribution.html
  aliases = ["${local.www_domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  // Here's where our certificate is loaded in!
  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.certificate.arn}"
    ssl_support_method  = "sni-only"
  }
}



resource "aws_cloudfront_distribution" "root_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
    domain_name = "${aws_s3_bucket.root.website_endpoint}"
    origin_id   = "${local.root_domain_name}"
  }

  enabled             = true

  // Experimenting with removing default root object in root distribution.
  //default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${local.root_domain_name}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["${local.root_domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.certificate.arn}"
    ssl_support_method  = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "files_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
    domain_name = "${aws_s3_bucket.file_share.website_endpoint}"
    origin_id   = "${local.file_share_domain_name}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${local.file_share_domain_name}"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["${local.file_share_domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate.certificate.arn}"
    ssl_support_method  = "sni-only"
  }
}
```

Now that the rest of our infrastructure is in place, we need to configure DNS in amazon route53. We will have our DNS 
entries point to our cloud front distributions. Those CloudFront distributions each point to their own S3 Buckets. One 
of the S3 buckets (root) redirects traffic to the other (www).

#### route53.tf

```terraform
// We want AWS to host our zone so its nameservers can point to our CloudFront
// distribution.
resource "aws_route53_zone" "zone" {
  name = "${local.root_domain_name}"
}

// This Route53 record will point at our CloudFront distribution.
resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.zone.zone_id}"
  name    = "${local.www_domain_name}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.www_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.www_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root" {
  zone_id = "${aws_route53_zone.zone.zone_id}"

  // NOTE: name is blank here.
  name = ""
  type = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.root_distribution.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.root_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

// FILES Subdomain

// Main zone needs to have an entry pointing to subdomain name servers
// https://aws.amazon.com/premiumsupport/knowledge-center/create-subdomain-route-53/
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone

resource "aws_route53_record" "root_files_subdomain_entry" {
  zone_id = "${aws_route53_zone.zone.zone_id}"

  // NOTE: name is blank here.
  name = "${local.file_share_domain_name}"
  type = "NS"
  ttl = "30"
  records = aws_route53_zone.files_subdomain_zone.name_servers
}

resource "aws_route53_zone" "files_subdomain_zone" {
  name = "${local.file_share_domain_name}"

}
```

Now, if I initialize `terraform init` and `terraform plan` I will see every intended resource being provisioned in the 
terraform plan. I will then provision all my infrastructure with `terraform apply`

Terraform does not have support for [managing registered domains](https://github.com/hashicorp/terraform-provider-aws/issues/88)
so once the hosted zone is generated you need to fetch the name servers from it & update the "registered domain" in 
route53 to match.

## Deployments & CloudFront Cache Invalidations

Deployments for this site are still crude. For now, I'm using a homemade deployer shell script. I leverage the aws cli 
this to:

* Sync assets to the www S3 bucket
* Create a CloudFront Invalidation event

```shell
#!/usr/bin/env bash

# Declarations
WWW_CLOUDFRONT_ID="YOUR-DISTRIBUTION-ID"
WWW_S3_BUCKET_NAME="www.johnsosoka.com"


cat soso-banner
echo ""
echo ""

build_artifacts()
{
  echo "Building ${WWW_S3_BUCKET_NAME}.."

  bundle exec jekyll build
  if [ $? -eq 0 ]
  then
    echo "Successfully built artifacts..."

  else
    echo "Something went wrong executing jekyll build. Please check jekyll log for more details."
    echo "Exiting..."
    exit 1
  fi
}

sync_artifacts_to_s3()
{
  aws s3 sync ./_site/ s3://${WWW_S3_BUCKET_NAME}
  if [ $? -eq 0 ]
  then
    echo "Assets uploaded to production bucket: ${WWW_S3_BUCKET_NAME}"

  else
    echo "Something went wrong syncing artifacts to production. Check aws-cli output for more details."
    echo "Exiting..."
    exit 1
  fi
}

invalidate_cloudfront_distribution()
{
  echo "Invalidating cloudfront distribution: ${WWW_CLOUDFRONT_ID}"
  aws cloudfront create-invalidation --distribution-id ${WWW_CLOUDFRONT_ID} --paths "/*"
}


echo "Building Jekyll Artifacts...."
build_artifacts

echo "Syncing assets to production..."
sync_artifacts_to_s3

echo "Invalidating distribution Id: ${WWW_CLOUDFRONT_ID}"
invalidate_cloudfront_distribution
```

Please note that in the script I cat a banner file which is not provided here. Locally I have some ascii art for my 
websites print out upon deployment. You can see that I solve the runatlantis problem of waiting for CloudFront cache 
to clear by creating a CloudFront Invalidation Event via the AWSCLI.

In future iterations, I will set up either a CodeCommit or Jenkins pipeline so that merges to master will build & deploy 
artifacts for me. Until then, I'll be living in the stone age and manually triggering my deployment script.



---
layout: post
title: "How to Use GitHub Actions to Deploy a Website to AWS S3"
category: blog
tags: GitHub Ations CI/CD pipeline AWS S3 deployment automation continuious deployment delivery terraform IAM Jekyll CloudFront
---


## Introduction

Shortly after creating this website 3 years ago I decided that I should set up a deployment pipeline, so that the website
was automatically updated whenever I published changes. Instead of doing that I productively procrastinated and continued
perfecting this [deploy.sh](https://gist.github.com/johnsosoka/e6897f4d6705704972c014d84ec7b6b1) script which I'd run from 
my local with either `./deploy.sh stage` or `./deploy.sh prod` depending on my target environment. 

Well, today that changes! I'm going to pull myself out of the stone age and bring myself into the modern era... I'm going 
to introduce an automated CI/CD pipeline for my personal website using GitHub Actions, and I'll be covering the process
in this post today.

**What is a CI/CD Pipeline?** A CI/CD pipeline is a process that automates the steps required to build, test, and deploy
software. My website is a static site, so there isn't much to test, I just need to generate artifacts and deploy them to 
S3.

### Existing Infrastructure

The infrastructure for this website is pretty simple. It's a static website hosted on Amazon S3. (The details on how my 
website is created are captured in [this post](/blog/2021/09/20/terraform-provision-blog-infra.html).)

The code to generate it and terraform to provision it is located on [GitHub](https://github.com/johnsosoka/jscom-blog/tree/main).
I use CloudFront to serve the website over HTTPS and Route53 to manage the DNS records. My website is generated using a 
static site generator called [Jekyll](https://jekyllrb.com/). My website is powered by 3 total S3 buckets:

1. johnsosoka.com
2. www.johnsosoka.com
3. stage.johnsosoka.com

You can see that one of my buckets is a stage bucket. This is where I deploy changes to the website before I deploy them to
the live website. It's not locked down at the moment, so anyone can access it. I'll probably lock it down in the future, 
or at least generate a robots.txt file so that search engines don't index it :grimace: 

### Pipeline Overview

Since this website is generated, I do need the pipeline to install ruby and execute the `jekyll build` command to generate
the static assets, which will later be uploaded to S3.

I want the pipeline to deploy to different S3 targets depending on different conditions. If I push or merge to `master` I want to deploy
to the `live website`. For pushes to `non-master` branches I want to deploy to the `stage website`. After it has deployed to the correct
target I want to invalidate the CloudFront cache so that the changes are reflected immediately.

My plan for automatically deploying non-master branches to the stage website wouldn't work in a typical CI/CD pipeline with
multiple contributors. I'm the only contributor to this website, so I can get away with it `:)`. If I had multiple contributors
I'd establish a different branching convention and workflow so that non-master branches would not constantly overwrite each other
in the stage environment.

## Setting up the Pipeline

### Create a Deployment User

GitHub Actions is going to require an IAM user with permissions to deploy to S3 and invalidate caches. Following the principle of least privilege
I'm going to create a new IAM user that only has permissions to interact with my johnsosoka.com related S3 buckets. Additionally, this
new user will have permissions to invalidate CloudFront distribution caches.

My website is entirely managed by Terraform, so I'm going to create this user using Terraform. First, I'll create a new 
`iam.tf` file in my `infrastructure` directory. I'll add the following to it:

```terraform
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
        "arn:aws:s3:::${aws_s3_bucket.www.id}/*",
        "arn:aws:s3:::${aws_s3_bucket.root.id}/*",
        "arn:aws:s3:::${aws_s3_bucket.stage.id}/*"
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
```

The above terraform is pretty straight-forward. It creates a new IAM user `github-deployer-user`, an access key for that 
user, and a policy that allows the user to interact with my S3 buckets and invalidate CloudFront caches. I've also added 
two outputs, the user access key id & the access key value itself (which is marked `sensitive=true` in terraform to prevent 
logging it to the console when terraform executes.) These outputs will be used as secret variables in my GitHub Actions 
pipeline and allow the GitHub runner to interact with my AWS account.

I'll execute and see the following, I've redacted the access_key_id but terraform did indeed print it to the console. The 
key secret was masked as expected by terraform as `<secret>`.


```
Outputs:

github_deployer_user_access_key_id = "[REDACTED]"
github_deployer_user_access_key_secret = <sensitive>
```

The masked value can be retrieved with the following command:
```commandline
terraform output -raw github_deployer_user_access_key_secret
```

### Configure GitHub Secrets

Now that I have a new IAM user for GitHub to use, I need to add the access key id and secret to my GitHub repository so
that the Actions pipeline can use them. I'll navigate to my repository on GitHub and click on `Settings` > 
`Secrets and variables` > `Actions` and then select `New repository secret`. I've added secrets for both the access key id
and other aws resources that I need my script to interact with, the final result looks like this:

![GitHub Secrets](/assets/img/blog/gitlab-pipeline/secrets-config.png)

With all secrets configured, I can now move on to writing the pipeline.

## Write the Pipeline

GitHub requires that a pipeline be defined in a specific directory. My file will be located in  `.github/workflows/jscom-build-deploy.yml`.
All the steps to build and deploy my website will be defined in this file. 

### Pipeline Events

```yaml
name: Deploy to S3 and Invalidate CloudFront

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main
```

The above is the start of my pipeline, I've defined some events that will trigger the pipeline to run. I want the pipeline executed
when a pull request is opened or updated against the `main` branch, and when a push is made to the `main` branch.


### Set up Build Environment

Next I'm going to define the job that will execute the pipeline. I'll call it `deploy` and it will run on the `ubuntu-latest` image.
This will be doing some preliminary work like checking out the repository and installing ruby.

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 2.7
          bundler-cache: true

```

Moving through the job definition. Now that I have ruby installed, we can install the ruby gems that are required to build the website.

### Generate the Website

```yaml

      - name: Build site
        run: |
          cd website
          bundle install
          bundle exec jekyll build
          cd ..

```

In the above step I'm executing a shell script that will change directories into the `website` directory, install the jekyll requirements,
and then generate the static website assets. The assets ultimately end up in the `website/_site` directory. Once the assets are generated
I have the script change back to the project's root directory.

### Deploy to S3

Now that the website assets are generated, we'll configure the aws cli and then sync the assets to the appropriate S3 bucket. Here in the 
pipeline I'm accessing the secrets that I configured earlier via `{% raw %}${{ secrets.SECRET_NAME }}{% endraw %}`. I'm also using a conditional to determine 
which S3 bucket to sync to based on the event that triggered the pipeline. If the event was a pull request, I'll sync to the `stage` bucket 
and if it was a push to the `main` branch, I'll sync to the `www` and `root` buckets.

```yaml
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: {% raw %}${{ secrets.AWS_ACCESS_KEY_ID }}{% endraw %}
          aws-secret-access-key: {% raw %}${{ secrets.AWS_SECRET_ACCESS_KEY }}{% endraw %}
          aws-region: {% raw %}${{ secrets.AWS_REGION }}{% endraw %}

      - name: Upload to S3
        run: |
          if [[ "{% raw %}${{ github.event_name }}{% endraw %}" == "pull_request" ]]; then
            aws s3 sync ./website/_site/ s3://{% raw %}${{ secrets.STAGE_S3_BUCKET_NAME }}{% endraw %}
          else
            aws s3 sync ./website/_site/ s3://{% raw %}${{ secrets.WWW_S3_BUCKET_NAME }}{% endraw %}
            aws s3 sync ./website/_site/ s3://{% raw %}${{ secrets.ROOT_S3_BUCKET_NAME }}{% endraw %}
          fi
```

### Invalidate CloudFront

The final portions of the pipeline will invalidate the CloudFront caches. This just makes the new website assets available 
immediately, which is great for those of us who might be a little impatient :).

```yaml
      - name: Invalidate CloudFront Distribution(s)
        run: |
          if [[ "{% raw %}${{ github.event_name }}{% endraw %}" == "pull_request" ]]; then
            aws cloudfront create-invalidation --distribution-id {% raw %}${{ secrets.STAGE_CLOUDFRONT_ID }}{% endraw %}} --paths "/*"
          else
            aws cloudfront create-invalidation --distribution-id {% raw %}${{ secrets.WWW_CLOUDFRONT_ID }}{% endraw %} --paths "/*"
            aws cloudfront create-invalidation --distribution-id {% raw %}${{ secrets.ROOT_CLOUDFRONT_ID }}{% endraw %} --paths "/*"
          fi
```

Again, I'm using a conditional to determine which CloudFront distribution to invalidate based on our target environment.

### Final Pipeline

Queue the music, it's the final pipeline!

Here's what it looks like in its entirety:

```yaml
# -----------------------------------------------------------
# Deploy Jekyll site to S3 and invalidate CloudFront cache
# Author: John Sosoka
# Date: 2023-07-14
# -----------------------------------------------------------

name: Deploy to S3 and Invalidate CloudFront

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 2.7
          bundler-cache: true

      - name: Build site
        run: |
          cd website
          bundle install
          bundle exec jekyll build
          cd ..

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: {% raw %}${{ secrets.AWS_ACCESS_KEY_ID }}{% endraw %}
          aws-secret-access-key: {% raw %}${{ secrets.AWS_SECRET_ACCESS_KEY }}{% endraw %}
          aws-region: {% raw %}${{ secrets.AWS_REGION }}{% endraw %}

      - name: Upload to S3
        run: |
          if [[ "{% raw %}${{ github.event_name }}{% endraw %}" == "pull_request" ]]; then
            aws s3 sync ./website/_site/ s3://{% raw %}${{ secrets.STAGE_S3_BUCKET_NAME }}{% endraw %}
          else
            aws s3 sync ./website/_site/ s3://{% raw %}${{ secrets.WWW_S3_BUCKET_NAME }}{% endraw %}
            aws s3 sync ./website/_site/ s3://{% raw %}${{ secrets.ROOT_S3_BUCKET_NAME }}{% endraw %}
          fi

      - name: Invalidate CloudFront Distribution(s)
        run: |
          if [[ "{% raw %}${{ github.event_name }}{% endraw %}" == "pull_request" ]]; then
            aws cloudfront create-invalidation --distribution-id {% raw %}${{ secrets.STAGE_CLOUDFRONT_ID }}{% endraw %}} --paths "/*"
          else
            aws cloudfront create-invalidation --distribution-id {% raw %}${{ secrets.WWW_CLOUDFRONT_ID }}{% endraw %} --paths "/*"
            aws cloudfront create-invalidation --distribution-id {% raw %}${{ secrets.ROOT_CLOUDFRONT_ID }}{% endraw %} --paths "/*"
          fi
```

## Conclusion

Well, that's it! I've got a pipeline that will build my website and deploy it to S3! Better yet, it will deploy
to a different target "environment" based on the event that triggered the pipeline.


![GitHub Actions Pipeline](/assets/img/blog/gitlab-pipeline/pipeline.png)

It's satisfying to see the pipeline run successfully! I have written Jenkins pipelines in the past, this was my first time 
writing a GitHub Actions pipeline. I have to say, I'm impressed with how easy it was to get up and running.

In the future, I may split organize the pipeline into multiple jobs and possibly have a job that runs tests. Although,
when generating a static website, there's not much to test.

This has been a _very long overdue_ upgrade to my website, and I hope that this blog post has been helpful to you.
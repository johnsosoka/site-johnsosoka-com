---
layout: post
title: Creating a Serverless Solution for Handling "Contact Me" Form Submissions
tags: aws python lambda sns terraform boto3 serverless http forms 
---

My website doesn't have comments on it, and I intentionally have not exposed an e-mail address (for fear
of getting overwhelmed by bots). I am writing more and more and would like to provide some avenues for folks
to send me feedback/suggestions/corrections. I figured I could find a free service to listen for Form Submissions &
send me an e-mail--boy was I wrong. Every service I found charged--FormSpree charged $10/month for a feature restricted
_personal plan_.

I decided I should just create my own backend service to handle contact me submissions.

## Design & Overview

* Python Lambdas
* SNS
* Api Gateway
* Terraform

## Python Development

Overview

* use boto3 client to publish to sns
* expect environment variable to be available with topic ARN 
* model object & json helper (in the future I can just add fields to the model, json automatically updates)
* project outline
  * Tests separate & not uploaded with app (lambda charges)


## Terraform

As with all of my other johnsosoka-com related projects, I want to capture & provision all needed infrastructure for 
this in terraform. The lambda function presents a new issue to be solved in that a zip must be created & then uploaded 
to aws. After some research I decided that I would try to utilize the terraform-aws-modules' 
[lambda](https://registry.terraform.io/modules/terraform-aws-modules/lambda/) module to build & deploy my code.

Before using the lambda module, I need to lay some groundwork. First things first, I need to set up my `main.tf` file.
This is where I like to specify the Terraform provider & backend.

**main.tf**
```terraform
provider "aws" {
  region = "us-east-1"
}

// Terraform state managed remotely.
terraform {
  backend "s3" {
    bucket         = "johnsosoka-com-tf-backend"
    key            = "project/jscom-contact-listener/state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state"
  }
}
```

You may have noticed that my terraform backend is a remote s3 backend. Depending on your use case, you may decide to use
 a local Terraform backend. I use a remote backend because I want a method for different terraform managed project to 
reference output & resources provisioned by each other.

Next up, I like to configure a `variables.tf` file to house common variables to be used throughout. It's a great to
practice housing variables in recognizable locations--It makes changes in the future much more manageable.

**variables.tf**
```terraform
variable "contact_me_topic_name" {
  default = "johnsosoka-com-contact-me-submission"
}

variable "lambda_name" {
  default = "contact-me-listener-svc"
}
```

After setting up the variables referred to below, I went ahead and utilized the module in the following file:

**lambda.tf**
```terraform
module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = var.lambda_name
  description   = "contact me submission listener"
  handler       = "handler.lambda_handler"
  runtime       = "python3.8"
  source_path = "../src/"

  environment_variables = {
    TOPIC_ARN = aws_sns_topic.contact_me_topic.arn
  }

  tags = {
    Name = "contact-me-listener-svc"
  }
}
```

This was my first time using a Terraform module. The Intellij terraform plugin did me a solid and suggested that I perform
a `terraform get` which created a `modules` directory within the (already .gitignored) `.terraform` folder. Terroform fetched
the module contents and stashed them in the newly created directory.


---
layout: post
title: Creating a Serverless Backend to Handle HTML Form Submissions  with Api-Gateway, S3, Lambda, and SNS.
category: blog
tags: aws python lambda sns terraform boto3 serverless http forms 
---

My website doesn't have comments on it, and I intentionally have not exposed an e-mail address (for fear
of getting overwhelmed by bots). I am writing more and more and would like to provide some avenues for folks
to send me feedback/suggestions/corrections. I figured I could find a free service to listen for Form Submissions &
send me an e-mail--boy was I wrong. Every service I found charged--FormSpree charged $10/month for a feature restricted
_personal plan_.

I decided I should just create my own backend service to handle contact me submissions.

## Design & Overview

I decided to take advantage of some AWS serverless offerings to build my form submission service. Below is a high-level
overview of how I will utilize each. The Contact-me form submission originates from the client, but is provided by
resources hosted on an S3 bucket.

![overview](/assets/img/blog/contact-form-prj/form-submission-svc.png)

The gist is that I will have an html form post to an api gateway endpoint (for nice url formatting & more granular control) 
API gateway will then forward the request to a lambda which will then validate the message, transform it to json & then 
publish the transformation to an SQS topic. This will give me the ability to have multiple subscribers for the contact-me 
SQS topic. For now, I have just subscribed with my e-mail. In the future, I will set up a lambda to read the json message
and provide nicer formatting before e-mailing me.

## Python Development

I will spare going into too many details with the lambda function. You can review the 
[code here](https://github.com/johnsosoka/jscom-contact-services/tree/main/contact-me-listener-svc/src)

Some design considerations: 
* Since terraform will know the ARN of the topic created, I'm setting an environment variable with the target ARN
* The Lambda application will then fetch the desired ARN from the environment & publish accordingly.
* I keep my test dir outside of `src` so when this is bundled & uploaded content in the test dir won't add to lambda execution costs.

At the end of the day, the python lambda simply:
* [validates input](https://github.com/johnsosoka/jscom-contact-services/blob/main/contact-me-listener-svc/src/app/validator/contact_event_validator.py)
* [converts the key/values to json](https://github.com/johnsosoka/jscom-contact-services/blob/main/contact-me-listener-svc/src/app/model/contact_me_submission.py#L39-L41)
* [publishes to sns](https://github.com/johnsosoka/jscom-contact-services/blob/main/contact-me-listener-svc/src/app/publisher/sns_publisher.py)
* [returns an execution status.](https://github.com/johnsosoka/jscom-contact-services/blob/main/contact-me-listener-svc/src/app/application.py#L65-L68)

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

You may have noticed that my terraform backend is a remote S3 backend. Depending on your use case, you may decide to use
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

Next up is to define the SNS topic. Sticking to the pattern of my previous projects, I broke these out mostly by resource.
If these projects get any larger or complicated, I will need to come up with a better strategy for dividing & naming files.

**sns.tf**
```terraform
resource "aws_sns_topic" "contact_me_topic" {
  name = var.contact_me_topic_name
}
```

After setting up the variables referred to below, I went ahead and utilized the lambda module in the following file:

**lambda.tf**
```terraform
module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = var.lambda_name
  description   = "contact me submission listener"
  handler       = "handler.lambda_handler"
  runtime       = "python3.8"
  source_path = "../src/"
  attach_policy_json = true
  policy_json        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "arn:aws:sns:*:*:*"
        }
    ]
}
EOF

  environment_variables = {
    TOPIC_ARN = aws_sns_topic.contact_me_topic.arn
  }

  tags = {
    Name = "contact-me-listener-svc"
  }
}

```

Note that I included & attached policy json to grant publish permissions to the SNS topic. Without this, my lambda would 
fail as an exception would be thrown when attempting to publish a message.

This was my first time using a Terraform module. The Intellij terraform plugin did me a solid and suggested that I perform
a `terraform get` which created a `modules` directory within the (already .gitignored) `.terraform` folder. Terraform fetched
the module contents and stashed them in the newly created directory.

The next chunk of terraform is the largest bit, I have this housed in a file api-gateway, but you may notice there are other
resources beyond api-gateway in this file.

**api-gateway.tf**

```terraform
data "terraform_remote_state" "jscom_common_data" {
  backend = "s3"
  config = {
    bucket = "johnsosoka-com-tf-backend"
    key = "project/johnsosoka.com-blog/state/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name = "/aws/gateway/contact_me_api_gateway_logs"

  tags = {
    site = "johnsosoka-com"
  }
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "${var.listener_api_name}-gateway"
  description   = "api gateway setup for contact me submissions"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["*"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  create_api_domain_name           = true


  # Custom domain
  domain_name                 = "api.johnsosoka.com"
  domain_name_certificate_arn = data.terraform_remote_state.jscom_common_data.outputs.jscom_acm_cert

  # Access logs
  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  # Routes and integrations
  integrations = {
    "POST /services/form/contact" = {
      lambda_arn             = module.lambda_function.lambda_function_invoke_arn
      payload_format_version = "2.0"

      timeout_milliseconds   = 12000
    }

    "$default" = {
      lambda_arn = module.lambda_function.lambda_function_invoke_arn
    }
  }

  tags = {
    Name = "http-api-gateway jscom-contact-me-listener-svc"
  }
}

# Invoke Permissions

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowContactServiceAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*/*"
}

resource "aws_route53_record" "api_gateway_dns" {
  name    = "api.johnsosoka.com"
  type    = "A"
  zone_id = data.terraform_remote_state.jscom_common_data.outputs.root_johnsosokacom_zone_id

  alias {
    evaluate_target_health = true
    name                   = module.api_gateway.apigatewayv2_domain_name_target_domain_name
    zone_id                 = module.api_gateway.apigatewayv2_domain_name_hosted_zone_id
  }
}
```
Working from top to bottom on this file, the first thing we encounter is a terraform_remote_state data object
named `jscom_common_data` this will fetch output variables from a separate project; Why do this? Well, I have
dns for my root/www domains managed in a separate repository. Setting up and referring to a remote state object
allows me to refer to the variable outputs from another project within this project. 

In the api-gateway module, you will see the first reference to `jscom_common_data` remote state data. I fetch the
same acm cert provisioned in my site-johnsosoka-com repo. You can view how my outputs are defined [here](https://github.com/johnsosoka/site-johnsosoka-com/blob/main/infrastructure/outputs.tf)

Note the `integrations` block, this is where the meat of the api-gateway work is:

```terraform
  # Routes and integrations
  integrations = {
    "POST /services/form/contact" = {
      lambda_arn             = module.lambda_function.lambda_function_invoke_arn
      payload_format_version = "2.0"

      timeout_milliseconds   = 12000
    }

    "$default" = {
      lambda_arn = module.lambda_function.lambda_function_invoke_arn
    }
  }
```

Notice that the method, path & lambda ARN are all specified here. So now when a qualifying request reaches
`/services/form/contact` the request will be forwarded to my lambda `module.lambda_function.lambda_function_invoke_arn`



## Contact-Me Form

The final piece of this project is the contact-me form. For V1, I'm just going to use a simple HTML form to submit the 
contact request. 

```html
<form action="{{ site.contact.api.url }}" method="{{ site.contact.api.method }}" >
  <ul>
    <li>
      <label for="name">Name:</label>
      <input type="text" id="name" name="user_name">
    </li>
    <li>
      <label for="mail">E-mail:</label>
      <input type="email" id="mail" name="user_email">
    </li>
    <li>
      <label for="msg">Message:</label>
      <textarea id="msg" name="user_message"></textarea>
    </li>
    <li class="button">
      <button type="submit">Send your message</button>
    </li>
  </ul>
</form>
```

In the current iteration of this, the contact me form redirects to the lambda & the response is rendered on the screen. 
In future versions, I will need to take advantage of some js library to fire in the background. Front end work is not a 
strength of mine, this will be a great opportunity to improve my lack of skills there.

## Conclusion

When the Terraform is executed, everything is created--the Route53 entry, the Api-Gateway API and SNS topic. My contact me
form lives on an s3 bucket, more details on that setup in [this blog post](/terraform-provision-blog-infra/). The only
manual step in this process was subscribing my e-mail to the sns topic--Amazon details this process [here](https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html).
Feel free to use the [contact me](/contact/) form & let me know if I should provide more details or correct anything :)


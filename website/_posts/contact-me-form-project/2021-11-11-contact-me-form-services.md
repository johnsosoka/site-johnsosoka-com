---
layout: post
title: Creating a Serverless Solution for Handling "Contact Me" Form Submissions
tags: aws python lambda sns terraform boto3 serverless http forms 
---

My website doesn't have comments on it, and I intentionally have not exposed an e-mail address (for fear
of getting overwhelmed by bots). I am writing more and more and would like to provide some avenues for folks
to send me feedback/suggestions/corrections. I figured I could find a free service to listen for Form Submissions &
send me an e-mail--boy was I wrong. Every service I found charged--FormSpree charged $10/month for a feature restricted
_personal plan_

I decided I should just create my own backend service to handle contact me submissions.

## Design & Overview

* Python Lambdas
* SNS
* Api Gateway
* Terraform


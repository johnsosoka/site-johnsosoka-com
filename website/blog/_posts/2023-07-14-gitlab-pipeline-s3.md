---
layout: post
title: "Creating a GitLab Pipeline to Deploy a static website to S3"
category: blog
tags: ai chatGPT vector datanbase vectors embeddings custom data NLP natural language processing similarity search openai python FAISS
---

Shortly after creating this website 3 years ago I decided that I should set up a deployment pipeline to make updating
the website easier. Suffice to say, I never got around to it and ignored my todo list item for years. That changes today!

Today we will be creating a GitLab pipeline that will deploy a static website to an S3 bucket. We'll be setting it up
for johnsosoka.com, which is currently hosted on AWS S3 and generated using the Jekyll site generator.

## Overview & Goals

## Deployment User
(Terraform for creating)

```
Outputs:

access_key_id = "READACTED"
secret_access_key = <sensitive>
```

**View Sensitive Output Variable**
```commandline
terraform output -raw secret_access_key
```

## Configure GitHub Secrets

## Write the Pipeline


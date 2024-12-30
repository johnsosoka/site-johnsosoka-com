---
layout: post
title: "Weekend Project: Serverless (AWS) Notion Database QR Code Generation service"
category: blog
tags: notion python qr-code serverless aws s3 lambda api-gateway
---

Last year (almost to the day) I wrote a "Note" which I consider less thought-out/organized as a blog post. It was about 
home organization with a Notion database & QR codes, originally posted [here](/note/2023/12/28/qr-code-box-organization.html). 
In that post, I had provided a Python script for bulk generation of QR codes linking them to items in a private Notion 
database. The gist of my project in that post was to print out QR codes & attach them to boxes in my garage for easy 
identification. As long as I maintained the Notion database entry for the related QR code, I could easily find the box I 
was looking for.

I was recently contacted teacher at a university who encountered my post and wanted to apply similar concepts to their
use case, managing a catalog of items that could be lent out to students. They required a more automated solution, where
an event in Notion could trigger a process to generate that QR code and attach it to the database entry. The teacher was
managing a database of hundreds of items, not tens of items like my home organization project. With so many items to manage,
generating QR codes manually & copying them to Notion manually would not only be tedious, but also error-prone. 



# The Project

After hearing about the teacher's use case, I decided that not only would my home storage project benefit from a more
robust solution, but that it's not every day that I get the opportunity to volunteer a few hours of development time to
benefit a University. I opted to take on the project and build a serverless service that would generate QR codes for a
given Notion integration & attach them to the related database entry. The school was short on money, and AWS would be
incredibly economical for managing thousands of items (but not millions).

## The Plan

Since I also intended to use this service, it needed the ability to handle multiple independent Notion integrations. I 
opted to accept the Notion integration key as a header in the webhook request, and the desired column name to attach the 
generated QR code to. At the time of writing, Notion did not support uploading files/images via their API, but they did 
support linking/embedding images hosted elsewhere. I decided to host the QR codes in an S3 bucket, and update the Notion 
database entry with the URL to the QR code in S3, using the Notion integration token supplied in the webhook request.

Headers are encrypted in https requests, so I wasn't concerned about the security of the Notion integration key as I could
force https requests to the API Gateway endpoint.

### The Draft

I started off by building a draft using ngrok to expose my local development environment to the internet. I created a 
simple FastAPI service that would accept a POST request, generate a QR code, and return the URL to the QR code. The
original draft was posted as a Github Gist [here](https://gist.github.com/johnsosoka/1ce8b0ac81cec27fb447093a1a99f196).

I've built simple FastAPI services before, but I've never had to host static assets with it. One key takeaway from this
draft was the following line of code from the gist:

```python
from fastapi import FastAPI, Request

# ...

app = FastAPI()

# Mount the directory to serve static files,
# This is how we host the QR codes for embedding in Notion
app.mount("/static", StaticFiles(directory=qr_code_dir), name="static")
```

This line of code mounts a directory to serve static files, which is how we host the QR codes for embedding in Notion. 
When it's exposed via the public ngrok URL, the QR codes can be embedded in Notion by linking to the `/static` directory
over https.

Since the draft was successful, and could embed QR codes in Notion (hosted via the static mount with FastAPI), I moved on 
to the next step: hosting the service on AWS. The plan was to use API Gateway to receive the webhook, Lambda to generate 
the QR code, and S3 to host the QR code--used to embed the QR code in Notion.

### The Service

I started off by adapting the FastAPI service to a lambda function. I no longer required the FastAPI dependency, and 
instead needed to host the static assets on AWS S3. From previous projects, I had already created a terraform module 
for hosting a static website on S3 with CloudFront in front of it. That module can be found [here](https://github.com/johnsosoka/jscom-tf-modules/tree/main/modules/static-website).
Luckily, I also already had an https:/media.johnsosoka.com bucket, which I could use to host the QR codes.



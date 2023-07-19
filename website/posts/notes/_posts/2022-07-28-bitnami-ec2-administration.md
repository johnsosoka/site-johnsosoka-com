---
layout: post
category: note
title: Bitnami EC2 Administration
note_type: AWS Misc
---

On a recent project I opted to utilize an image packaged by bitnami rather than setting up a 3rd party open source
project from scratch. Thus far I'm really impressed with how bitnami has assembled everything. Here are some notes
for quick reference.


## SSL Cert on Subdomain
Instead of using lets-encrypt's certbot, bitnami has a different utility which is just as easy to use.

```shell
sudo /opt/bitnami/bncert-tool
```
This tool has several prompts. 

* Provide the subdomain. ex.) `test.example.com` 
* skip adding www
* `Y` for http -> https redirect
* profit

The script takes a few minutes to run & will restart apache during this process.

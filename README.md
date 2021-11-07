# site-johnsosoka-com
content, assets, jekyll template &amp; terraform for https://www.johnsosoka.com

# about

This repository is split into two sections: infrastructure and website. Combined, these can provision & run a copy of
[my homepage](https://johnsosoka.com). Contained in the website directory are some scripts to build & host a local copy
of the website as well as a deployer script. 

**Requirements**

* aws cli installed & configured (check terraform-deployer account for credentials if needed)
* terraform cli installed & configured

## [Infrastructure](/infrastructure)

The Terraform directory includes all required terraform scripts to ensure the correct provisioning
of aws resources.



## [Website](/website)

The website directory includes all requires template files, scripts, image assets to run johnsosoka.com. It is a static generated site
using jekyll.


# Todo

* [ ] Deployment Pipelines
  * [ ] Build Artifacts & Sync to prod S3 bucket upon merge to main
  * [ ] Rollback capability??
* [x] Set up terraform s3 backend 
  * [x] S3 bucket for shared output variables & remote state management.
  * [x] DynamoDB table to backend locking mechanism.
* [x] Logging S3 bucket
  * [x] configure website access logging
* [x] Create independent files S3 bucket for keeping hosted download content separate from website content
  * [x] create related cloudfront resources 
  * [x] create related dns entries (route53 resources)
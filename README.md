# jscom-blog
content, assets, jekyll template &amp; terraform required to run https://johnsosoka.com

## Details

This repository is split into two sections: infrastructure and website. Combined, these can provision & run a copy of
[my homepage](https://johnsosoka.com). Contained in the website directory are some scripts to build & host a local copy
of the website as well as a deployer script. 

### Requirements
* Static site generator, [Jekyll](https://jekyllrb.com/docs/) & dependencies (ruby)
* AWS CLI installed & configured (including credential provisioning)
* Terraform 

## Repository Organization:
For more details on getting the site up & running visit a section's readme:

* **[Infrastructure](/infrastructure)** - Contains terraform to provision all required johnsosoka.com blog.
* **[Website](/website)** - Contains the Jekyll theme & Content for johnsosoka.com


## Todo
* [ ] Migrate from Jekyll to Pelican
* [ ] Deployment Pipelines
  * [ ] Build Artifacts & Sync to prod S3 bucket upon merge to main
  * ~~[ ] Rollback capability??~~
* [ ] Modernize template/move to bootstrap
* [x] Set up stage.johnsosoka.com
* [x] Set up terraform s3 backend 
  * [x] S3 bucket for shared output variables & remote state management.
  * [x] DynamoDB table to backend locking mechanism.
* [x] Logging S3 bucket
  * [x] configure website access logging
* [x] Create independent files S3 bucket for keeping hosted download content separate from website content
  * [x] create related cloudfront resources 
  * [x] create related dns entries (route53 resources)
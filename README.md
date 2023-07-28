# jscom-blog

Welcome to the repository for [My Homepage](https://johnsosoka.com). A personal blog, written by a software engineer
and lover-of-dogs currently living in Boise, Idaho. Writing about technology, software engineering, and my expanding family.

## About

My website is built using [Jekyll](https://jekyllrb.com/), a static site generator written in Ruby. The website is hosted
on [Amazon Web Services](https://aws.amazon.com/) using [Amazon S3](https://aws.amazon.com/s3/) and [Amazon CloudFront](https://aws.amazon.com/cloudfront/).
All the AWS resources are provisioned using [Terraform](https://www.terraform.io/). The website is deployed using either
a local script or via GitHub Actions.

The template for the jscom blog is [jscom-ice](https://github.com/johnsosoka/jscom-ice) and the Terraform modules used to 
provision the AWS resources are located in [jscom-tf-modules](https://github.com/johnsosoka/jscom-tf-modules) 


### Repository Structure

| Directory               | Description |
|-------------------------|-------------|
| [terraform](/terraform) | Contains Terraform scripts that provision all necessary AWS resources for the blog. |
| [website](/website)     | Contains the content for the blog. |
| [.github](/.github)     | Contains GitHub Actions workflows that automate the deployment of the website. |


## Getting Started

### Prerequisites

Ensure you have the following installed and configured:

- **Jekyll & dependencies (Ruby):** Install Ruby and then use Ruby's package manager to install Jekyll and Bundler. You can refer to the [Jekyll Documentation](https://jekyllrb.com/docs/installation/) for detailed instructions.
- **AWS CLI:** Download and install the AWS CLI from the [official AWS CLI website](https://aws.amazon.com/cli/). After installation, run `aws configure` in your terminal and follow the prompts to input your AWS credentials.
- **Terraform:** Download the appropriate package for your system from the [Terraform downloads page](https://www.terraform.io/downloads.html). Unzip the package and ensure that the `terraform` binary is available in your `PATH`.

### Running Locally

1. Navigate to the website directory
2. Install the dependencies with `bundle install` (or `bundle update` if you already have the dependencies installed)
3. Run the website locally with `bundle exec jekyll serve`
4. Open your web browser and navigate to [http://localhost:4000](http://localhost:4000) to visit the website.


## Deployment

### GitHub Actions

Deployments to both staging and production environments are also possible using GitHub Actions. The workflows for these
deployments share the following common steps:

- Installs Requirements / Sets up Ruby.
- Generates Assets with Jekyll.
- AWS Credentials Configured.
- Uploads Generated Assets to S3.
- Finally, the CloudFront distribution is invalidated to refresh the cache.

_Please ensure that the necessary AWS credentials and other secrets are stored in your GitHub repository's secrets section for these workflows to function correctly._

#### Stage Deployment
[![Deploy to STAGE](https://github.com/johnsosoka/jscom-blog/actions/workflows/deploy-stage.yml/badge.svg)](https://github.com/johnsosoka/jscom-blog/actions/workflows/deploy-stage.yml)

- Triggered **Manually**
- Actions -> Deploy to STAGE -> Select Branch -> Run Workflow
- Targets `https://stage.johnsosoka.com`
- Workflow File: `.github/workflows/deploy-stage.yml`

#### Prod Deployment
[![Deploy to PROD](https://github.com/johnsosoka/jscom-blog/actions/workflows/deploy-prod.yml/badge.svg?branch=main)](https://github.com/johnsosoka/jscom-blog/actions/workflows/deploy-prod.yml)

- Triggered **Automatically**
- Merges to `main` Branch Trigger Deployment
- Targets `https://johnsosoka.com` & `https://www.johnsosoka.com`
- Workflow File: `.github/workflows/deploy-prod.yml`

## AWS Website Infrastructure

Terrform is used to provision the AWS resources required to host the website. The infrastructure is defined in the 
`terraform` directory. It sets up three CloudFront distributions for the "www", "root", "media", and "stage" subdomains, 
along with corresponding S3 buckets. The Terraform state is managed remotely using an S3 backend. Please note that some shared 
resources may be defined in the [jscom-core-infrastructure](https://github.com/johnsosoka/jscom-core-infrastructure) 
repository. Additionally, the module used to provision the website is in [jscom-tf-modules](https://github.com/johnsosoka/jscom-tf-modules)

### Resources Provisioned

- CloudFront distributions for "www", "root", "media", and "stage" domains
- Media is used for assets such as images, videos, and other files
- S3 buckets for the www, root, media, and staging websites
- IAM user with deployer access and permissions (Used for GitHub Actions CI/CD)
- Route53 records for mapping subdomains to CloudFront distributions

Refer to the Terraform configuration files for more details.

### Usage

1. Install Terraform.
2. Set up your AWS credentials.
3. If Necessary, Modify the variables in `variables.tf`.
4. Run `terraform init` to initialize the backend and providers and fetch modules.
5. Run `terraform plan` to preview the infrastructure changes.
6. Run `terraform apply` to provision the AWS resources.

### Notes

- This infrastructure uses CloudFront as a content delivery network and S3 buckets to host the website content.
- The IAM user created has permissions to manage the S3 buckets and create CloudFront invalidations. It is intended to be used by the GitHub Actions workflows.
- The Terraform state is managed remotely using an S3 backend.

## Usage / Customizations

### Image Carousel

I have written a `carousel.html` include that can be used to display a carousel of images. It expects an array of strings
indicating image paths. You can easily configure images using the `_data/carousels.yml` file.

Add images to the yml file in the following format, name your collection i.e. `baby-moon-mccall` and then populate it
with the image paths.

```yaml
baby-moon-mccall:
  - /assets/img/slider/1/IMG_1061.jpeg
  - /assets/img/slider/1/IMG_1066.jpeg
  - /assets/img/slider/1/IMG_1075.jpeg
```

Wherever you'd like to display the carousel, add the following snippet:

```liquid
{% assign carousel = site.data.carousels['baby-moon-mccall'] %}

{% include carousel.html images=carousel %}
```

### Post Snippets

Posts may be published in multiple categories on this website, but I like to try and keep them somewhat organized. I
created the `posts.html` include to fetch posts of a particular category & display them in a list.

Example Usage:

```yaml

  {% raw %}
  {% include posts.html category="blog" post_display_limit=5 post_collection_title="Recent Blog Posts" %}
  {% endraw %}
```

This is currently used in the homepage as well as both the blog & notes landing pages.

## Contributing

While this is a personal blog and I don't expect any contributions I do still welcome them. If you have a suggestion or 
would like to contribute a post, please either reach out to me directly or fork this repository and submit a pull request.

## Todo

* [x] Separate theme--place into separate repository install via gem
* [x] create a terraform module for the website
* [ ] ~~Migrate from Jekyll to Pelican??~~
* [x] Modernize template/move to bootstrap
* [x] Deployment Pipelines
  * [x] Build Artifacts & Sync to prod S3 bucket upon merge to main
  * [ ] ~~Rollback capability??~~
* [x] Set up stage.johnsosoka.com
* [x] Set up terraform s3 backend
  * [x] S3 bucket for shared output variables & remote state management.
  * [x] DynamoDB table to backend locking mechanism.
* [x] Logging S3 bucket
  * [x] configure website access logging
* [x] Create independent files S3 bucket for keeping hosted download content separate from website content
  * [x] create related cloudfront resources
  * [x] create related dns entries (route e53 resources)

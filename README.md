# jscom-blog

Welcome to the repository for [My Homepage](https://johnsosoka.com). A personal blog, written by a software engineer
and dog lover currently living in Boise, Idaho. Writing about technology, software engineering, and my expanding family.


## About
This website is built using [Jekyll](https://jekyllrb.com/), a static site generator written in Ruby. The website is hosted
on [Amazon Web Services](https://aws.amazon.com/) using [Amazon S3](https://aws.amazon.com/s3/) and [Amazon CloudFront](https://aws.amazon.com/cloudfront/).
All the AWS resources are provisioned using [Terraform](https://www.terraform.io/). The website is deployed using either
a local script or via GitHub Actions.

## Repository Structure

Everything required to provision resources, build, and deploy the website is contained within this repository. The contents 
are logically structured into the following directories:

| Directory                         | Description |
|-----------------------------------|-------------|
| [infrastructure](/infrastructure) | Contains Terraform scripts that provision all necessary AWS resources for the blog. |
| [website](/website)               | Contains the Jekyll theme and the content for the blog. |
| [.github](/.github)               | Contains GitHub Actions workflows that automate the deployment of the website. |

## Scripts

The following scripts have been written to automate common tasks and simplify the deployment process:

| Script Name            | Description                                                                   | 
|------------------------|-------------------------------------------------------------------------------|
| `run-local.sh`         | Attempts to serve Jekyll locally at http://localhost:4000/                    |
| `configure_deployer.py` | Sets the required environment variables for the `deploy.sh` script            |
| `deploy.sh`        | Builds Jekyll, syncs to either stage or prod stage.johnsosoka.com / johnsosoka.com |

## Getting Started

### Prerequisites

Ensure you have the following installed and configured:

- **Jekyll & dependencies (Ruby):** Install Ruby and then use Ruby's package manager to install Jekyll and Bundler. You can refer to the [Jekyll Documentation](https://jekyllrb.com/docs/installation/) for detailed instructions.
- **AWS CLI:** Download and install the AWS CLI from the [official AWS CLI website](https://aws.amazon.com/cli/). After installation, run `aws configure` in your terminal and follow the prompts to input your AWS credentials.
- **Terraform:** Download the appropriate package for your system from the [Terraform downloads page](https://www.terraform.io/downloads.html). Unzip the package and ensure that the `terraform` binary is available in your `PATH`.

### Running Locally

1. Navigate to the root directory of the project in your terminal.
2. Execute `run-local.sh` to serve the website locally. This will start a local server where you can preview the website.
   ```bash
   ./run-local.sh
   ```
3. Open your web browser and navigate to [http://localhost:4000](http://localhost:4000) to visit the website.

_Please note that you might need to grant execute permissions to the `run-local.sh` script before running it. You can do this with the `chmod` command:_

```bash
chmod +x run-local.sh
```

## Deployment

### From Local

#### First Time Setup:

* Install [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html)
* Configure AWS CLI with `aws configure` (have a user provisioned on aws already, with access to the target S3 bucket)
* Execute `configure_deployer.py` to set the required environment variables for the `deploy.sh` script.

#### Deploy:

* Run `deploy.sh stage | prod` to build the website and sync the contents to the target S3 bucket. The deployment script also
  attempts to invalidate CloudFront caches.

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
`infrastructure` directory. It sets up three CloudFront distributions for the "www", "root", and "stage" subdomains, along 
with corresponding S3 buckets. The Terraform state is managed remotely using an S3 backend. Please note that some shared 
resources may be defined in the [jscom-core-infrastructure](https://github.com/johnsosoka/jscom-core-infrastructure) 
repository.

### Resources Provisioned

- CloudFront distributions for "www", "root", and "stage" domains
- S3 buckets for the www, root, and staging websites
- IAM user with deployer access and permissions (Used for GitHub Actions CI/CD)
- Route53 records for mapping subdomains to CloudFront distributions

Refer to the Terraform configuration files for more details.

### Usage

1. Install Terraform.
2. Set up your AWS credentials.
3. If Necessary, Modify the variables in `variables.tf`.
4. Run `terraform init` to initialize the backend and providers.
5. Run `terraform plan` to preview the infrastructure changes.
6. Run `terraform apply` to provision the AWS resources.

### Notes

- This infrastructure uses CloudFront as a content delivery network and S3 buckets to host the website content.
- The IAM user created has permissions to manage the S3 buckets and create CloudFront invalidations. It is intended to be used by the GitHub Actions workflows.
- The Terraform state is managed remotely using an S3 backend.

## Contributing

While this is a personal blog and I don't expect any contributions I do still welcome them. If you have a suggestion or 
would like to contribute a post, please either reach out to me directly or fork this repository and submit a pull request.

## Todo
* [ ] Migrate from Jekyll to Pelican
* [ ] Modernize template/move to bootstrap
* [x] Deployment Pipelines
  * [x] Build Artifacts & Sync to prod S3 bucket upon merge to main
  * ~~[ ] Rollback capability??~~
* [x] Set up stage.johnsosoka.com
* [x] Set up terraform s3 backend
  * [x] S3 bucket for shared output variables & remote state management.
  * [x] DynamoDB table to backend locking mechanism.
* [x] Logging S3 bucket
  * [x] configure website access logging
* [x] Create independent files S3 bucket for keeping hosted download content separate from website content
  * [x] create related cloudfront resources
  * [x] create related dns entries (route e53 resources)

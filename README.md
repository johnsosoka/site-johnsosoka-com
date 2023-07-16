# John Sosoka's Homepage Repository (jscom-blog)

Welcome to the repository for [John Sosoka's Homepage](https://johnsosoka.com). This repository houses all the necessary 
components, including the blog content, assets, Jekyll template, and Terraform scripts for infrastructure management.

## Repository Structure

The repository is organized into two primary sections: `infrastructure` and `website`. Together, these sections contain all the resources needed to provision and operate a replica of the blog.

- **[Infrastructure](/infrastructure)**: This directory contains Terraform scripts that provision all necessary AWS resources for the blog.

- **[Website](/website)**: This directory contains the Jekyll theme and the content for the blog.

## Getting Started

### Prerequisites

Ensure you have the following installed and configured:

- Jekyll & dependencies (Ruby)
- AWS CLI (configured with appropriate credentials)
- Terraform

### Local Setup

1. Install Jekyll and Ruby. Refer to the [Jekyll Documentation](https://jekyllrb.com/docs/installation/) for detailed instructions.
2. Execute `run-local.sh` to serve the website locally at [http://localhost:4000](http://localhost:4000).

## Deployment

### Local Deployment

1. Install and configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html).
2. Run `configure_deployer.py` to set the required environment variables for the `deploy.sh` script.
3. Execute `deploy.sh stage | prod` to build the website and sync the contents to the target S3 bucket. This script also attempts to invalidate CloudFront caches.

### Automated Deployment via GitHub Actions

Deployments to both staging and production environments are automated using GitHub Actions. The workflows for these deployments share the following common steps:

- The workflow checks out the repository and sets up Ruby with the specified version.
- The website is built using Jekyll.
- AWS credentials are configured using the secrets stored in the repository.
- The built site is then uploaded to the specified S3 bucket.
- Finally, the CloudFront distribution is invalidated to refresh the cache.

Please ensure that the necessary AWS credentials and other secrets are stored in your GitHub repository's secrets section for these workflows to function correctly.

#### Staging Deployment

The staging deployment is **triggered manually** from the GitHub Actions tab and targets `https://stage.johnsosoka.com`. The workflow file for this process is located at `.github/workflows/deploy-stage.yml`.

#### Production Deployment

The production deployment is **triggered automatically** when a commit is merged to the `main` branch. It targets `https://johnsosoka.com` & `https://www.johnsosoka.com`. The workflow file for this process is located at `.github/workflows/deploy-prod.yml`.

## License

The Jekyll Template used ([Klisé](/johnsosoka/jscom-blog/blob/main/website/klise.now.sh)) is under the [MIT License](/johnsosoka/jscom-blog/blob/main/website/JEKYLL_TEMPLATE_LICENSE).

All other content is under the [GPLv3 License](https://www.gnu.org/licenses/gpl-3.0.en.html).

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
  * [x] create related dns entries (route53 resources)
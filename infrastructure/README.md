# Infrastructure Setup

### Getting Started

1. Install **aws-cli**. Check out the [guide here](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html)
2. Configure aws-cli with `aws configure` (have a user provisioned on aws already)
3. Follow the [terraform installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli?)
4. Terraform should be able to execute on the johnsosoka-com account now.

## AWS Website Infrastructure

This repository contains Terraform configuration files to provision the infrastructure required for hosting a website on AWS. 
It sets up three CloudFront distributions for the "www", "root", and "stage" subdomains, along with corresponding S3 buckets.
The Terraform state is managed remotely using an S3 backend.

### Resources Provisioned

- CloudFront distributions for "www", "root", and "stage" subdomains
- S3 buckets for the www, root, and staging websites
- IAM user with deployer access and permissions (Used for GitHub Actions CO/CD)
- Route53 records for mapping subdomains to CloudFront distributions

### Usage

1. Install Terraform.
2. Set up your AWS credentials.
3. Modify the variables in `variables.tf` to match your desired configuration.
4. Run `terraform init` to initialize the backend and providers.
5. Run `terraform plan` to preview the infrastructure changes.
6. Run `terraform apply` to provision the AWS resources.

For detailed instructions, refer to the documentation or the comments in the Terraform configuration files.

### Notes

- This infrastructure uses CloudFront as a content delivery network and S3 buckets to host the website content.
- The IAM user created has permissions to manage the S3 buckets and create CloudFront invalidations.
- The Terraform state is managed remotely using an S3 backend.

### License

This repository is licensed under the [MIT License](LICENSE). Feel free to modify and use the code according to your requirements.

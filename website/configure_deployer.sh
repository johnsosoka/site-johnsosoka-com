#!/bin/bash
echo "This script will set environment variables to your shell rc file for the jscom deployer script."
# Prompt the user for input
read -p "Enter the CloudFront ID for your website: " cloudfront_id
read -p "Enter the S3 bucket name for your website: " s3_bucket_name

# Set the environment variables in the correct shell rc file
if [ -f ~/.bashrc ]; then
  echo "export WWW_CLOUDFRONT_ID=$cloudfront_id" >> ~/.bashrc
  echo "export WWW_S3_BUCKET_NAME=$s3_bucket_name" >> ~/.bashrc
  source ~/.bashrc
  echo "Environment variables set in ~/.bashrc"
elif [ -f ~/.zshrc ]; then
  echo "export WWW_CLOUDFRONT_ID=$cloudfront_id" >> ~/.zshrc
  echo "export WWW_S3_BUCKET_NAME=$s3_bucket_name" >> ~/.zshrc
  source ~/.zshrc
  echo "Environment variables set in ~/.zshrc"
else
  echo "Unable to set environment variables. No supported shell rc file found."
fi

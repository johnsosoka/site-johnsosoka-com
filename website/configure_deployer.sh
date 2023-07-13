#!/bin/bash
#
# configure_deployer.sh
#
# Description:
# This script configures environment variables required by the deploy_prod.sh script.
# It supports both bash and zsh shells.
#
# Environment Variables:
# The following environment variables are set by this script:
# - WWW_CLOUDFRONT_ID: CloudFront ID for your website
# - WWW_S3_BUCKET_NAME: S3 bucket name for your website
# - ROOT_CLOUDFRONT_ID: Root CloudFront ID
# - ROOT_S3_BUCKET_NAME: Root S3 bucket name
#
# Usage:
# Run this script directly to be prompted for the values of these environment variables.
# If a variable is already set, the script will prompt you to replace the existing value.
# The script will update the corresponding shell rc file (~/.bashrc or ~/.zshrc).
#
# Author: john sosoka
# Date: 2023-07-12



# Function to read input and set environment variables
set_env_variable() {
  local var_name=$1
  local prompt_message=$2
  local file=$3

  local old_val=$(grep "^export $var_name=" "$file" | cut -d'=' -f2)

  if [ -n "$old_val" ]; then
    read -p "$var_name is currently set to $old_val. Do you want to replace it? [Y/n]: " replace
    if [ "$replace" != "Y" ] && [ "$replace" != "y" ]; then
      return
    fi
  fi

  read -p "$prompt_message" new_val

  # Remove old variable definition, if it exists
  sed -i "/^export $var_name=.*/d" "$file"

  # Add new variable definition
  echo "export $var_name=$new_val" >> "$file"
}

echo "This script will set environment variables to your shell rc file for the jscom deployer script."

# If ~/.bashrc exists, use it as the shell rc file
if [ -f ~/.bashrc ]; then
  shell_rc_file="~/.bashrc"
# Else, if ~/.zshrc exists, use it as the shell rc file
elif [ -f ~/.zshrc ]; then
  shell_rc_file="~/.zshrc"
else
  echo "Unable to set environment variables. No supported shell rc file found."
  exit 1
fi

# Set the environment variables
set_env_variable "WWW_CLOUDFRONT_ID" "Enter the CloudFront ID for your website: " "$shell_rc_file"
set_env_variable "WWW_S3_BUCKET_NAME" "Enter the S3 bucket name for your website: " "$shell_rc_file"
set_env_variable "ROOT_CLOUDFRONT_ID" "Enter the Root CloudFront ID: " "$shell_rc_file"
set_env_variable "ROOT_S3_BUCKET_NAME" "Enter the Root S3 bucket name: " "$shell_rc_file"

source $shell_rc_file

echo "Environment variables set in $shell_rc_file"

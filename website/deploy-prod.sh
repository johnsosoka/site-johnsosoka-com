#!/usr/bin/env bash

# Author: john sosoka
#
# Overview: builds Jekyll artifacts & syncs them to an s3 bucket.
#
#
# Set environment variables:
#     WWW_CLOUDFRONT_ID - to id of distribution which must be invalidated upon deployment.
#     WWW_S3_BUCKET_NAME - to name of target s3 bucket.
#

cat soso-banner
echo ""
echo ""

build_artifacts()
{
  echo "Building ${WWW_S3_BUCKET_NAME}.. artifacts"
  if bundle exec jekyll build
  then
    echo "Successfully built artifacts..."

  else
    echo "Something went wrong executing jekyll build. Please check jekyll log for more details."
    echo "Exiting..."
    exit 1
  fi
}

sync_artifacts_to_s3()
{
  echo "syncing assets to target bucket: ${WWW_S3_BUCKET_NAME}"
  if aws s3 sync ./_site/ s3://"${WWW_S3_BUCKET_NAME}"
  then
    echo "Assets uploaded to production bucket: ${WWW_S3_BUCKET_NAME}"

  else
    echo "Something went wrong syncing artifacts to production. Check aws-cli output for more details."
    echo "Exiting..."
    exit 1
  fi
}

invalidate_cloudfront_distribution()
{
  echo "Invalidating cloudfront distribution: ${WWW_CLOUDFRONT_ID}"
  aws cloudfront create-invalidation --distribution-id "${WWW_CLOUDFRONT_ID}" --paths "/*"
}



build_artifacts
sync_artifacts_to_s3
invalidate_cloudfront_distribution
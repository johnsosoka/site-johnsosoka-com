#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Script Name: run-local.sh
# Usage:       ./run-local.sh
# Description: This script serves a local instance of johnsosoka.com. It first
#              navigates to the website directory, checks if Jekyll is installed,
#              and then serves the website using Jekyll. The script also handles
#              script termination and prints appropriate exit messages.
# Author:      John Sosoka
# Date:        2023-07-16
# Version:     1.0
# First Release Date: 2021-11-08
# -----------------------------------------------------------------------------

# Variables
WEBSITE_NAME="johnsosoka.com"
WEBSITE_DIR="./website/"

# Navigate to the website directory
cd $WEBSITE_DIR || { echo "Could not navigate to the website directory. Please check the path and try again."; exit 1; }

echo "Starting local instance of $WEBSITE_NAME"
cat soso-banner

# Check if Jekyll is installed
if ! command -v jekyll &> /dev/null
then
    echo "Jekyll could not be found. Please install Jekyll first. You can do this by running 'gem install jekyll bundler'."
    exit 1
fi

# Function to handle script termination
handle_exit() {
    echo "$1"  # Print the exit message
    exit 1
}

# Trap the SIGTERM signal and call handle_exit
trap 'handle_exit "The script was stopped. $1"' SIGTERM

# Serve Jekyll locally
echo "Serving $WEBSITE_NAME locally..."
bundle exec jekyll serve

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

#!/bin/bash

set_website_dir() {
  # Prompt the user for the location
  echo "Please enter the location of the jscom jekyll website directory:"
  read WEBSITE_DIR

  # Identify the shell and add an appropriate export variable
  if [[ $SHELL == *"zsh"* ]]; then
    echo "export WEBSITE_DIR=$WEBSITE_DIR" >> ~/.zshrc
  elif [[ $SHELL == *"bash"* ]]; then
    echo "export WEBSITE_DIR=$WEBSITE_DIR" >> ~/.bashrc
  fi

  # Temporarily set WEBSITE_DIR for the current script
  export WEBSITE_DIR

  # Inform the user
  echo "The WEBSITE_DIR variable has been temporarily set for this script. For the change to persist in future sessions, please source your shell's rc file. For bash, use 'source ~/.bashrc'. For zsh, use 'source ~/.zshrc'."
}

# Check if WEBSITE_DIR is not set
if [[ -z "${WEBSITE_DIR}" ]]; then
  set_website_dir
else
  echo "WEBSITE_DIR is already set to $WEBSITE_DIR. Continuing..."
fi


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

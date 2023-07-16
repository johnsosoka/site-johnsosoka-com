#!/usr/bin/env bash
#!/bin/bash

# Navigate to the website directory
cd ./website/
echo "starting local instance of johnsosoka.com"
cat soso-banner
# Check if Jekyll is installed
if ! command -v jekyll &> /dev/null
then
    echo "Jekyll could not be found. Please install Jekyll first."
    exit
fi

# Function to handle script termination
function handle_exit {
    echo "$1"  # Print the exit message
    exit
}

# Trap the SIGTERM signal and call handle_exit
trap 'handle_exit "The script was stopped. $1"' SIGTERM

# Serve Jekyll locally
echo "Serving Jekyll locally..."
bundle exec jekyll serve

#!/usr/bin/env bash

cd website
cat soso-banner

echo "starting local instance of johnsosoka.com"

bundle exec jekyll serve

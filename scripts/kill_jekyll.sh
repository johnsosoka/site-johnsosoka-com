#!/bin/bash

# Find the process ID of Jekyll running on port 4000
jekyll_pid=$(lsof -i tcp:4000 -t)

# Check if the process ID is found
if [ -n "$jekyll_pid" ]; then
  echo "Jekyll is running with PID $jekyll_pid. Killing the process..."

  # Kill the process
  kill -9 $jekyll_pid

  echo "Jekyll process has been killed."
else
  echo "Jekyll is not running."
fi

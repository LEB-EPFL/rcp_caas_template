#!/usr/bin/env sh

set -e

timestamp=$(date +"%Y%m%d%H%M%S")
filename="hello_leb_$timestamp.txt"

echo "Hello, LEB!" | tee /scratch/"$filename"

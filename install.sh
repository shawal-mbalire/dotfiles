#!/bin/bash

set -e

REPO_URL="https://github.com/shawal-mbalire/root_home_shawal"
TEMP_DIR=$(mktemp -d)
REPO_NAME="root_home_shawal"

echo "Cloning repository to temporary directory..."
git clone "$REPO_URL" "$TEMP_DIR/$REPO_NAME"

echo "Moving contents to home directory..."
# Use rsync to copy all files including hidden ones and .git
rsync -avhu --progress "$TEMP_DIR/$REPO_NAME/" "$HOME/"

echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

echo "Installation complete! All files (including .git) have been moved to $HOME"

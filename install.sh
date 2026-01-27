#!/bin/bash

set -e

REPO_URL="https://github.com/shawal-mbalire/root_home_shawal"
TEMP_DIR=$(mktemp -d)
REPO_NAME=$(basename "$REPO_URL")

echo "Cloning repository to temporary directory..."
if ! git clone "$REPO_URL" "$TEMP_DIR/$REPO_NAME"; then
    echo "Error: Failed to clone repository"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Copying contents to home directory..."
# Use rsync to copy all files including hidden ones and .git
rsync -avhu --progress "$TEMP_DIR/$REPO_NAME/" "$HOME/"

echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

echo "Installation complete! All files (including .git) have been copied to $HOME"

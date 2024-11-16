#!/bin/bash

echo "Starting setup process..."
CHAIN_NAME="inco"
CHAIN_ID="21097"
RPC_URL="https://validator.rivest.inco.org"

echo "Initializing registry..."
hyperlane registry init

METADATA_FILE="$HOME/.hyperlane/chains/$CHAIN_NAME/metadata.yaml"

echo "Setting up core contracts..."
export HYP_KEY="$PRIVATE_KEY"
hyperlane core init

echo "Deploying core contracts..."
hyperlane core deploy

ADDRESSES_FILE="$HOME/.hyperlane/chains/$CHAIN_NAME/addresses.yaml"

echo "Sending test message..."
hyperlane send message --relay

echo "Setting up token bridging..."
echo "Refer to the documentation for next steps."

echo "Submitting to registry..."
REGISTRY_PATH="$HOME/.hyperlane"
LOGO_PATH="$REGISTRY_PATH/chains/$CHAIN_NAME/logo.svg"
if [ ! -f "$LOGO_PATH" ]; then
    echo "Add logo.svg to $LOGO_PATH"
    exit 1
fi

yamllint "$REGISTRY_PATH"

cd "$REGISTRY_PATH" || exit
git init
git add .
git commit -m "Register $CHAIN_NAME with Hyperlane"

git remote add canonical git@github.com:hyperlane-xyz/hyperlane-registry.git
git pull canonical main --rebase

git remote add origin "your-fork-url"
git push origin main

echo "Create a pull request with a detailed changeset."
echo "Setup complete."

#!/bin/bash
# Build and push the Better-ComfyUI Docker image with llama-cpp-python CUDA support
set -euo pipefail

cd "$(dirname "$0")/.."

# Check we're on the right branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "patched/master" ]; then
    echo "Error: must be on patched/master branch (currently: $BRANCH)"
    exit 1
fi

echo "Building Docker image..."
docker build \
    -t tuiteraz/better-comfyui:latest \
    -t tuiteraz/better-comfyui:250b2e95 \
    .

echo "Pushing to registry..."
docker push tuiteraz/better-comfyui:latest
docker push tuiteraz/better-comfyui:250b2e95

echo "Done!"

#!/bin/bash
# Build and push the Better-ComfyUI Docker image with llama-cpp-python CUDA support
set -euo pipefail

cd "$(dirname "$0")/.."

# Check we're on the right branch (patched/master or a versioned patched/master-*)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "patched/master" ] && [[ "$BRANCH" != patched/master-* ]]; then
    echo "Error: must be on patched/master or a patched/master-* branch (currently: $BRANCH)"
    exit 1
fi

PROMOTE_LATEST=false
for arg in "$@"; do
    case "$arg" in
        --promote-latest) PROMOTE_LATEST=true ;;
        *) echo "Error: unknown argument: $arg"
           exit 1 ;;
    esac
done

# Immutable build provenance: tag is the short SHA of the current commit
TAG=$(git rev-parse --short HEAD)

echo "Building Docker image..."
docker build \
    -t "tuiteraz/better-comfyui:$TAG" \
    .

echo "Pushing to registry..."
docker push "tuiteraz/better-comfyui:$TAG"

# :latest is the deployment trigger — push it only via an explicit --promote-latest run
if [ "$PROMOTE_LATEST" = true ]; then
    echo "Promoting to :latest..."
    docker push "tuiteraz/better-comfyui:latest"
fi

echo "Done!"

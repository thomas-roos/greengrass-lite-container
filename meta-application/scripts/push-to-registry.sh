#!/bin/bash
set -e

OCI_IMAGE_PATH="$1"
REGISTRY_URL="$2"
IMAGE_NAME="${3:-greengrass-lite-container}"
TAG="${4:-latest}"

if [ -z "$OCI_IMAGE_PATH" ] || [ -z "$REGISTRY_URL" ]; then
    echo "Usage: $0 <oci-image-path> <registry-url> [image-name] [tag]"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/image.tar docker.io/username/repo"
    echo "  $0 /path/to/image.tar localhost:5000/myimage myapp v1.0"
    echo ""
    echo "For authenticated registries, set:"
    echo "  export REGISTRY_USER=username"
    echo "  export REGISTRY_PASS=password"
    exit 1
fi

# Check if skopeo is installed
if ! command -v skopeo &> /dev/null; then
    echo "Installing skopeo..."
    sudo apt-get update && sudo apt-get install -y skopeo
fi

# Build authentication flags
AUTH_FLAGS=""
if [ -n "$REGISTRY_USER" ] && [ -n "$REGISTRY_PASS" ]; then
    AUTH_FLAGS="--dest-creds ${REGISTRY_USER}:${REGISTRY_PASS}"
fi

echo "Pushing OCI image to registry..."
echo "  Source: $OCI_IMAGE_PATH"
echo "  Destination: ${REGISTRY_URL}/${IMAGE_NAME}:${TAG}"

skopeo copy ${AUTH_FLAGS} \
    oci-archive:${OCI_IMAGE_PATH} \
    docker://${REGISTRY_URL}/${IMAGE_NAME}:${TAG}

echo "✅ Successfully pushed to ${REGISTRY_URL}/${IMAGE_NAME}:${TAG}"

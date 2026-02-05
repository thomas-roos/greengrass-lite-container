#!/bin/bash
set -e

REGISTRY="${1:-docker.io/library}"
IMAGE_NAME="${2:-greengrass-lite-2layer}"
TAG="${3:-latest}"

if [ "$REGISTRY" = "docker.io/library" ]; then
    echo "Usage: $0 <registry> [image-name] [tag]"
    echo ""
    echo "Example: $0 docker.io/myuser greengrass-lite-2layer v1"
    echo "         $0 ghcr.io/myorg greengrass-lite-2layer latest"
    exit 1
fi

echo "Building multi-arch manifest for: $REGISTRY/$IMAGE_NAME:$TAG"
echo ""

BUILD_DIR="/home/ubuntu/data/greengrass-lite-container/bitbake-builds/bitbake-setup-greengrass-lite-container-distro_poky-machine_qemuarm64/build"

# Build both architectures
echo "==> Building ARM64 and x86-64..."
cd /home/ubuntu/data/greengrass-lite-container
. $BUILD_DIR/init-build-env
bitbake greengrass-lite-2layer
bitbake multiconfig:vruntime-x86-64:greengrass-lite-2layer

ARM64_TAR="$BUILD_DIR/tmp/deploy/images/qemuarm64/greengrass-lite-2layer-latest-oci.tar"
X86_TAR="$BUILD_DIR/tmp-vruntime-x86-64/deploy/images/qemux86-64/greengrass-lite-2layer-latest-oci.tar"

echo "ARM64 image: $ARM64_TAR"
echo "x86-64 image: $X86_TAR"

# Push ARM64
echo "==> Pushing ARM64..."
skopeo copy oci-archive:$ARM64_TAR docker://$REGISTRY/$IMAGE_NAME:$TAG-arm64

# Push x86-64
echo "==> Pushing x86-64..."
skopeo copy oci-archive:$X86_TAR docker://$REGISTRY/$IMAGE_NAME:$TAG-amd64

# Create manifest
echo "==> Creating multi-arch manifest..."
docker manifest create $REGISTRY/$IMAGE_NAME:$TAG \
    --amend $REGISTRY/$IMAGE_NAME:$TAG-arm64 \
    --amend $REGISTRY/$IMAGE_NAME:$TAG-amd64

docker manifest push $REGISTRY/$IMAGE_NAME:$TAG

echo ""
echo "✅ Multi-arch manifest created: $REGISTRY/$IMAGE_NAME:$TAG"
echo "   - linux/arm64"
echo "   - linux/amd64"

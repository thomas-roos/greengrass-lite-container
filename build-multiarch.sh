#!/bin/bash
set -e

IMAGE_NAME="${1:-greengrass-lite-2layer}"
TAG="${2:-latest}"

echo "Creating multi-arch OCI image: $IMAGE_NAME:$TAG"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/bitbake-builds/bitbake-setup-greengrass-lite-container-distro_poky-machine_qemuarm64/build"

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found: $BUILD_DIR"
    echo "Run bitbake-setup init first"
    exit 1
fi

# Build both architectures
echo "==> Building ARM64 and x86-64..."
cd "$SCRIPT_DIR"
. $BUILD_DIR/init-build-env
bitbake greengrass-lite-2layer
bitbake multiconfig:vruntime-x86-64:greengrass-lite-2layer

ARM64_TAR="$BUILD_DIR/tmp/deploy/images/qemuarm64/greengrass-lite-2layer-latest-oci.tar"
X86_TAR="$BUILD_DIR/tmp-vruntime-x86-64/deploy/images/qemux86-64/greengrass-lite-2layer-latest-oci.tar"

echo "ARM64 image: $ARM64_TAR"
echo "x86-64 image: $X86_TAR"

# Load both images to local storage
echo "==> Loading images to local storage..."
skopeo copy oci-archive:$ARM64_TAR containers-storage:localhost/$IMAGE_NAME:$TAG-arm64
skopeo copy oci-archive:$X86_TAR containers-storage:localhost/$IMAGE_NAME:$TAG-amd64

# Create multi-arch manifest
echo "==> Creating multi-arch manifest..."
podman manifest create $IMAGE_NAME:$TAG
podman manifest add $IMAGE_NAME:$TAG containers-storage:localhost/$IMAGE_NAME:$TAG-arm64
podman manifest add $IMAGE_NAME:$TAG containers-storage:localhost/$IMAGE_NAME:$TAG-amd64

echo ""
echo "✅ Multi-arch manifest created: $IMAGE_NAME:$TAG"
podman manifest inspect $IMAGE_NAME:$TAG | grep -E "architecture|os" | head -10

echo ""
echo "To push to registry:"
echo "  podman manifest push $IMAGE_NAME:$TAG docker://registry.example.com/$IMAGE_NAME:$TAG"
echo ""
echo "To use locally:"
echo "  podman run --rm $IMAGE_NAME:$TAG uname -m"

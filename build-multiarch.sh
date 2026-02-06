#!/bin/bash
set -e

IMAGE_NAME="${1:-greengrass-lite}"
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
bitbake multiconfig:vruntime-aarch64:greengrass-lite-2layer
bitbake multiconfig:vruntime-x86-64:greengrass-lite-2layer

ARM64_OCI="$BUILD_DIR/tmp-vruntime-aarch64/deploy/images/qemuarm64/greengrass-lite-2layer-latest-oci"
X86_OCI="$BUILD_DIR/tmp-vruntime-x86-64/deploy/images/qemux86-64/greengrass-lite-2layer-latest-oci"

echo "ARM64 OCI: $ARM64_OCI"
echo "x86-64 OCI: $X86_OCI"

# Create multi-arch manifest using buildah
echo "==> Creating multi-arch manifest..."
buildah manifest rm $IMAGE_NAME:$TAG 2>/dev/null || true
buildah manifest create $IMAGE_NAME:$TAG
buildah manifest add $IMAGE_NAME:$TAG oci:$ARM64_OCI
buildah manifest add $IMAGE_NAME:$TAG oci:$X86_OCI

echo ""
echo "✅ Multi-arch manifest created: $IMAGE_NAME:$TAG"
buildah manifest inspect $IMAGE_NAME:$TAG | grep -E "architecture|os" | head -10

echo ""
echo "To push to registry:"
echo "  buildah manifest push --all $IMAGE_NAME:$TAG docker://ghcr.io/YOUR_USERNAME/$IMAGE_NAME:$TAG"

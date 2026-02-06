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

# Build multi-arch image (both architectures)
echo "==> Building multi-arch image..."
cd "$SCRIPT_DIR"
. $BUILD_DIR/init-build-env
bitbake greengrass-lite-multiarch

MULTIARCH_OCI="$BUILD_DIR/tmp/deploy/images/qemuarm64/greengrass-lite-multiarch-multiarch-oci"

echo ""
echo "✅ Multi-arch OCI image created: $MULTIARCH_OCI"
echo ""
echo "To push to registry:"
echo "  skopeo copy --all oci:$MULTIARCH_OCI docker://ghcr.io/YOUR_USERNAME/$IMAGE_NAME:$TAG"

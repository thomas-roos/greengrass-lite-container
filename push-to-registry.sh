#!/bin/bash
set -e

REGISTRY="${1:-ghcr.io}"
REPO="${2}"
TAG="${3:-latest}"
GITHUB_REPO="${4}"

if [ -z "$REPO" ]; then
    echo "Usage: $0 [registry] <repo> [tag] [github-repo]"
    echo ""
    echo "Example: $0 ghcr.io myuser/greengrass-lite latest myuser/greengrass-lite-container"
    echo "         $0 ghcr.io myorg/greengrass-lite v1.0 myorg/repo-name"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/bitbake-builds/bitbake-setup-greengrass-lite-container-distro_poky-machine_qemuarm64/build"

ARM64_OCI="$BUILD_DIR/tmp-vruntime-aarch64/deploy/images/qemuarm64/greengrass-lite-2layer-latest-oci"
AMD64_OCI="$BUILD_DIR/tmp-vruntime-x86-64/deploy/images/qemux86-64/greengrass-lite-2layer-latest-oci"

if [ ! -d "$ARM64_OCI" ] || [ ! -d "$AMD64_OCI" ]; then
    echo "Error: OCI images not found"
    echo "ARM64: $ARM64_OCI"
    echo "AMD64: $AMD64_OCI"
    echo "Run: bitbake greengrass-lite-multiarch"
    exit 1
fi

echo "Pushing multi-arch OCI to $REGISTRY/$REPO:$TAG"
if [ -n "$GITHUB_REPO" ]; then
    echo "Linking to GitHub repository: $GITHUB_REPO"
fi
echo ""

# Push individual platform images
echo "Pushing ARM64 image..."
skopeo copy --all oci:$ARM64_OCI docker://$REGISTRY/$REPO:$TAG-arm64

echo "Pushing AMD64 image..."
skopeo copy --all oci:$AMD64_OCI docker://$REGISTRY/$REPO:$TAG-amd64

# Create multi-arch manifest from pushed images
echo ""
echo "Creating multi-arch manifest..."
buildah manifest rm greengrass-lite:multiarch 2>/dev/null || true
buildah manifest create greengrass-lite:multiarch
buildah manifest add greengrass-lite:multiarch docker://$REGISTRY/$REPO:$TAG-arm64
buildah manifest add greengrass-lite:multiarch docker://$REGISTRY/$REPO:$TAG-amd64
buildah manifest push --all greengrass-lite:multiarch docker://$REGISTRY/$REPO:$TAG

# If GitHub repo specified, add label to link package to repo
if [ -n "$GITHUB_REPO" ] && [ "$REGISTRY" = "ghcr.io" ]; then
    echo ""
    echo "To link package to repository, add this label to your Dockerfile or recipe:"
    echo "  org.opencontainers.image.source=https://github.com/$GITHUB_REPO"
fi

echo ""
echo "✅ Pushed to $REGISTRY/$REPO:$TAG"
echo ""
echo "Pull with:"
echo "  docker pull $REGISTRY/$REPO:$TAG"
echo "  podman pull $REGISTRY/$REPO:$TAG"

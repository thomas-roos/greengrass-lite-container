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

OCI_DIR="/home/ubuntu/data/greengrass-lite-container/bitbake-builds/bitbake-setup-greengrass-lite-container-distro_poky-machine_qemuarm64/build/tmp/deploy/images/qemuarm64/greengrass-lite-multiarch-multiarch-oci"

if [ ! -d "$OCI_DIR" ]; then
    echo "Error: Multi-arch OCI not found at $OCI_DIR"
    echo "Run: bitbake greengrass-lite-multiarch"
    exit 1
fi

echo "Pushing multi-arch OCI to $REGISTRY/$REPO:$TAG"
if [ -n "$GITHUB_REPO" ]; then
    echo "Linking to GitHub repository: $GITHUB_REPO"
fi
echo ""

# Push using skopeo (preserves multi-arch manifest)
skopeo copy \
    --all \
    oci:$OCI_DIR \
    docker://$REGISTRY/$REPO:$TAG

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

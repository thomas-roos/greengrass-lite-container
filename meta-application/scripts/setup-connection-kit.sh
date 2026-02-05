#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONNECTION_KIT_ZIP="$1"
VOLUME_BASE="/var/snap/greengrass-lite-container/current/docker-volumes"

if [ -z "$CONNECTION_KIT_ZIP" ]; then
    echo "Usage: $0 <connection-kit.zip>"
    exit 1
fi

if [ ! -f "$CONNECTION_KIT_ZIP" ]; then
    echo "Error: Connection kit not found: $CONNECTION_KIT_ZIP"
    exit 1
fi

echo "Creating volume directories..."
sudo mkdir -p "$VOLUME_BASE/etc-greengrass"
sudo mkdir -p "$VOLUME_BASE/var-lib-greengrass"
sudo mkdir -p "$VOLUME_BASE/opt-greengrass-components"

echo "Extracting connection kit..."
TEMP_DIR=$(mktemp -d)
unzip -q "$CONNECTION_KIT_ZIP" -d "$TEMP_DIR"

echo "Copying certificates and config..."
sudo cp -r "$TEMP_DIR"/* "$VOLUME_BASE/etc-greengrass/"
sudo chmod -R 755 "$VOLUME_BASE"

rm -rf "$TEMP_DIR"
echo "Volume setup complete!"
echo "Volumes ready at: $VOLUME_BASE"

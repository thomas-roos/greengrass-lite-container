#!/bin/bash
set -e

CONNECTION_KIT_ZIP="$1"
VOLUME_BASE="${2:-./volumes}"

if [ -z "$CONNECTION_KIT_ZIP" ]; then
    echo "Usage: $0 <connection-kit.zip> [volume-dir]"
    echo ""
    echo "Example: $0 connectionKit.zip"
    echo "         $0 connectionKit.zip ./volumes"
    exit 1
fi

if [ ! -f "$CONNECTION_KIT_ZIP" ]; then
    echo "Error: Connection kit not found: $CONNECTION_KIT_ZIP"
    exit 1
fi

echo "Setting up Greengrass Lite volumes..."
echo "Connection kit: $CONNECTION_KIT_ZIP"
echo "Volume base: $VOLUME_BASE"

# Create volume directories
mkdir -p "$VOLUME_BASE/etc-greengrass/config.d"
mkdir -p "$VOLUME_BASE/var-lib-greengrass"

# Extract connection kit to etc-greengrass
echo "Extracting connection kit..."
unzip -o "$CONNECTION_KIT_ZIP" -d "$VOLUME_BASE/etc-greengrass"

# Update config.yaml with actual paths
CONFIG_FILE="$VOLUME_BASE/etc-greengrass/config.yaml"
if [ -f "$CONFIG_FILE" ]; then
    echo "Updating config.yaml paths..."
    sed -i 's|{{config_dir}}|/etc/greengrass|g' "$CONFIG_FILE"
    sed -i 's|{{nucleus_component}}|aws.greengrass.NucleusLite|g' "$CONFIG_FILE"
fi

# Set permissions (private key must be readable by ggcore user in container)
chmod 644 "$VOLUME_BASE/etc-greengrass/private.pem.key"
chmod 644 "$VOLUME_BASE/etc-greengrass/device.pem.crt"
chmod 644 "$VOLUME_BASE/etc-greengrass/AmazonRootCA1.pem"
chmod 644 "$VOLUME_BASE/etc-greengrass/config.yaml"

echo ""
echo "✅ Volumes created successfully!"
echo ""
echo "Start container with:"
echo "  docker compose up -d"
echo "  # or"
echo "  podman compose up -d"
echo ""
echo "Or manually:"
echo "  docker run -d --name greengrass-lite \\"
echo "    --privileged \\"
echo "    --tmpfs /run --tmpfs /run/lock \\"
echo "    -v $VOLUME_BASE/etc-greengrass:/etc/greengrass \\"
echo "    -v $VOLUME_BASE/var-lib-greengrass:/var/lib/greengrass \\"
echo "    greengrass-lite-2layer:v5"

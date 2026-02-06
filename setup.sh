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

# Extract greengrass-lite.yaml from image if not already present
if [ ! -f "$VOLUME_BASE/etc-greengrass/config.d/greengrass-lite.yaml" ]; then
    echo "Extracting greengrass-lite.yaml from image..."
    podman run --rm --entrypoint /bin/sh ghcr.io/thomas-roos/greengrass-lite:latest -c "cat /etc/greengrass/config.d/greengrass-lite.yaml" > "$VOLUME_BASE/etc-greengrass/config.d/greengrass-lite.yaml" 2>/dev/null || \
    docker run --rm --entrypoint /bin/sh ghcr.io/thomas-roos/greengrass-lite:latest -c "cat /etc/greengrass/config.d/greengrass-lite.yaml" > "$VOLUME_BASE/etc-greengrass/config.d/greengrass-lite.yaml" 2>/dev/null || \
    echo "Warning: Could not extract greengrass-lite.yaml from image"
fi

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

# Create resolv.conf for container DNS
echo "nameserver 8.8.8.8" > "$VOLUME_BASE/resolv.conf"

echo ""
echo "✅ Volumes created successfully!"
echo ""
echo "Start container:"
echo "  podman-compose up -d"
echo "  # or"
echo "  docker-compose up -d"

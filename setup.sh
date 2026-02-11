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
mkdir -p "$VOLUME_BASE/var-lib-containers"
mkdir -p "$VOLUME_BASE/systemd-system"

# Extract greengrass-lite.yaml from image if not already present
if [ ! -f "$VOLUME_BASE/etc-greengrass/config.d/greengrass-lite.yaml" ]; then
    echo "Extracting greengrass-lite.yaml from image..."
    
    # Pull image if not available locally
    if ! podman image exists ghcr.io/thomas-roos/greengrass-lite:latest 2>/dev/null && \
       ! docker image inspect ghcr.io/thomas-roos/greengrass-lite:latest >/dev/null 2>&1; then
        echo "Pulling image ghcr.io/thomas-roos/greengrass-lite:latest..."
        podman pull ghcr.io/thomas-roos/greengrass-lite:latest 2>/dev/null || \
        docker pull ghcr.io/thomas-roos/greengrass-lite:latest
    fi
    
    # Extract config file from image
    if podman run --rm --entrypoint /bin/sh ghcr.io/thomas-roos/greengrass-lite:latest -c "cat /etc/greengrass/config.d/greengrass-lite.yaml" > "$VOLUME_BASE/etc-greengrass/config.d/greengrass-lite.yaml" 2>/dev/null; then
        echo "Extracted greengrass-lite.yaml"
    elif docker run --rm --entrypoint /bin/sh ghcr.io/thomas-roos/greengrass-lite:latest -c "cat /etc/greengrass/config.d/greengrass-lite.yaml" > "$VOLUME_BASE/etc-greengrass/config.d/greengrass-lite.yaml" 2>/dev/null; then
        echo "Extracted greengrass-lite.yaml"
    else
        echo "Error: Could not extract greengrass-lite.yaml from image"
        exit 1
    fi
fi

# Extract systemd system directory from image if empty
if [ -z "$(ls -A "$VOLUME_BASE/systemd-system" 2>/dev/null)" ]; then
    echo "Extracting systemd system directory from image..."
    
    # Create temporary container to copy files
    TEMP_CONTAINER=$(podman create ghcr.io/thomas-roos/greengrass-lite:latest 2>/dev/null || docker create ghcr.io/thomas-roos/greengrass-lite:latest)
    
    if [ -n "$TEMP_CONTAINER" ]; then
        # Copy the directory contents
        if podman cp "$TEMP_CONTAINER:/etc/systemd/system/." "$VOLUME_BASE/systemd-system/" 2>/dev/null || \
           docker cp "$TEMP_CONTAINER:/etc/systemd/system/." "$VOLUME_BASE/systemd-system/" 2>/dev/null; then
            echo "Extracted systemd configuration"
        else
            echo "Warning: Could not extract systemd system directory from image"
        fi
        
        # Remove temporary container
        podman rm "$TEMP_CONTAINER" >/dev/null 2>&1 || docker rm "$TEMP_CONTAINER" >/dev/null 2>&1
    else
        echo "Warning: Could not create temporary container"
    fi
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

echo ""
echo "✅ Volumes created successfully!"
echo ""
echo "Storage: Using overlay driver with persistent storage at ./volumes/var-lib-containers"
echo ""
echo "Start container:"
echo "  podman-compose up -d"
echo "  # or"
echo "  docker-compose up -d"
echo ""
echo "Test nested container deployment:"
echo "  See README.md 'Deploying Container Components' section"
echo "  Quick test: Deploy the AlpineEcho example component"

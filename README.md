# Greengrass Lite Container

Multi-layer OCI container with AWS Greengrass Lite and systemd, built using Yocto and meta-virtualization.

## Prerequisites

**For building:**
- Yocto build dependencies (see [Yocto Quick Start](https://docs.yoctoproject.org/brief-yoctoprojectqs/index.html))
- `buildah` or `podman` for multi-arch manifest creation
- `skopeo` for OCI image operations

**For running:**
- `docker` or `podman`
- `docker-compose` or `podman-compose` (optional)

**Install on Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install podman buildah skopeo
```

## Quick Start

### On Build System

1. **Setup build env:**
   ```bash
   cd /path/to/bitbake/bin
   ./bitbake-setup --setting default top-dir-prefix $PWD/../../greengrass-lite-container init \
     $PWD/../../greengrass-lite-container/bitbake-setup.conf.json \
     greengrass-lite-container machine/qemuarm64 distro/poky application/greengrass-lite-container \
     --non-interactive

   cd ../../greengrass-lite-container
   . ./bitbake-builds/bitbake-setup-greengrass-lite-container-distro_poky-machine_qemuarm64/build/init-build-env
   ```

2. **Build multi-arch (ARM64 + x86-64):**
   ```bash
   bitbake greengrass-lite-multiarch
   ```

3. **Push to registry:**
   ```bash
   ./push-to-registry.sh ghcr.io YOUR_USERNAME/greengrass-lite latest YOUR_USERNAME/greengrass-lite-container
   ```

4. **Setup with your AWS IoT connection kit:**
   ```bash
   ./setup.sh connectionKit.zip
   ```

5. **Start container:**
   ```bash
   docker-compose up -d
   ```

### On Target System (Using Pre-built Image)

1. **Download setup files:**
   ```bash
   curl -O https://raw.githubusercontent.com/thomas-roos/greengrass-lite-container/master/setup.sh
   curl -O https://raw.githubusercontent.com/thomas-roos/greengrass-lite-container/master/compose.yaml
   chmod +x setup.sh
   ```

2. **Create container volume from connection kit:**
   ```bash
   ./setup.sh connectionKit.zip
   ```

3. **Start container:**
   ```bash
   docker-compose up -d
   # or
   podman-compose up -d
   ```

   To use a locally built image instead:
   ```bash
   sed -i 's|image:.*|image: greengrass-lite-2layer:latest|' compose.yaml
   ```

4. **Stop container:**
   ```bash
   docker-compose down
   # or
   podman-compose down

   # Force stop if hanging:
   podman rm -f greengrass-lite
   # or
   docker rm -f greengrass-lite
   ```

5. **Debug logs:**
   ```bash
   # Follow all logs
   podman exec greengrass-lite journalctl -f
   # or
   docker exec greengrass-lite journalctl -f
   
   # Check Greengrass service status
   podman exec greengrass-lite systemctl status ggl.core.iotcored.service
   ```

## Architecture

**2-Layer Design:**
- **Layer 1 (54MB):** systemd + base system + usrmerge-compat
- **Layer 2 (32MB):** Greengrass Lite + services

**Benefits:**
- Base layer rarely changes, efficient updates
- Application layer updates are small (32MB)
- Shared base across multiple containers

**C Library:**
- Uses **glibc** (GNU C Library) for maximum compatibility
- Supports pre-built binaries and third-party Greengrass components
- Most AWS and community components expect glibc

## Configuration

**Volumes:**
- `./volumes/etc-greengrass` - Certificates and config
- `./volumes/var-lib-greengrass` - Runtime data
- `./volumes/var-lib-containers` - Container images and layers (persistent overlay storage)

**Container Storage:**
- Uses **overlay** driver for efficient layer sharing
- Nested container images persist across restarts
- Storage location: `./volumes/var-lib-containers`

**Connection Kit:**
The `setup.sh` script extracts your AWS IoT connection kit and configures:
- Device certificates
- Private key (with correct permissions for ggcore user)
- Root CA certificate
- config.yaml with NucleusLite component

## Push to GitHub Container Registry

1. **Authenticate with GitHub:**
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

2. **Push the multi-arch image:**
   ```bash
   ./push-to-registry.sh ghcr.io USERNAME/greengrass-lite latest
   ```

The image will be available at: `ghcr.io/USERNAME/greengrass-lite:latest`

## Verification

```bash
# Check systemd status
podman exec greengrass-lite systemctl status greengrass-lite.target

# Check IoT Core connection
podman exec greengrass-lite systemctl status ggl.core.iotcored.service

# View logs
podman exec greengrass-lite journalctl -u ggl.core.iotcored.service -f
```

## Deploying Container Components

Greengrass Lite supports running nested containers using Podman. Here's a complete example of deploying a simple Alpine container component.

**1. Create Component Recipe (container-component-recipe.json):**
```json
{
  "RecipeFormatVersion": "2020-01-25",
  "ComponentName": "com.example.AlpineEcho",
  "ComponentVersion": "1.0.11",
  "ComponentType": "aws.greengrass.generic",
  "ComponentDescription": "Simple Alpine container that echoes a message",
  "ComponentPublisher": "Example",
  "Manifests": [
    {
      "Platform": {
        "os": "linux",
        "runtime": "aws_nucleus_lite"
      },
      "Lifecycle": {
        "run": "podman run --rm --network=slirp4netns --name alpine-demo alpine:latest sh -c 'while true; do echo \"Container running at $(date)\"; sleep 10; done'"
      }
    }
  ]
}
```

**2. Create Deployment Configuration (deployment.json):**
```json
{
  "targetArn": "arn:aws:iot:REGION:ACCOUNT_ID:thing/THING_NAME",
  "components": {
    "com.example.AlpineEcho": {
      "componentVersion": "1.0.11"
    }
  }
}
```

Replace `REGION`, `ACCOUNT_ID`, and `THING_NAME` with your actual values.

**3. Deploy to Device:**
```bash
# Create component version
aws greengrassv2 create-component-version \
  --region REGION \
  --inline-recipe fileb://container-component-recipe.json

# Deploy to device
aws greengrassv2 create-deployment \
  --region REGION \
  --cli-input-json file://deployment.json
```

**4. View Component Logs:**
```bash
# Inside the Greengrass container
podman exec greengrass-lite journalctl -f | grep AlpineEcho
```

## Build Details

**Recipe:** `meta-application/recipes-greengrass-lite-2layer/greengrass-lite-2layer/greengrass-lite-2layer.bb`

**Key Features:**
- OCI_LAYERS multi-layer support from meta-virtualization container-cross-install branch
- usrmerge-compat package for /bin, /sbin, /lib symlinks
- Systemd services masked for container environment
- /var/volatile directories created at build time

## References

- [meta-virtualization container-cross-install](https://git.yoctoproject.org/meta-virtualization/log/?h=container-cross-install)
- [meta-aws](https://github.com/aws/meta-aws)
- [AWS Greengrass Lite](https://github.com/aws-greengrass/aws-greengrass-lite)

# Greengrass Lite Container

Multi-layer OCI container with AWS Greengrass Lite and systemd, built using Yocto and meta-virtualization.

## Quick Start

### On Build System

1. **Build the image:**
   ```bash
   bitbake-setup init
   . ./bitbake-builds/bitbake-setup-greengrass-lite-container-distro_poky-machine_qemuarm64/build/init-build-env
   bitbake greengrass-lite-2layer
   ```

2. **Build multi-arch (ARM64 + x86-64):**
   ```bash
   # Enable multiconfig in conf/local.conf:
   echo 'BBMULTICONFIG = "vruntime-aarch64 vruntime-x86-64"' >> conf/local.conf
   
   # Build both architectures
   bitbake greengrass-lite-2layer
   bitbake multiconfig:vruntime-x86-64:greengrass-lite-2layer
   ```

3. **Load to Docker/Podman:**
   ```bash
   # ARM64
   skopeo copy oci-archive:tmp/deploy/images/qemuarm64/greengrass-lite-2layer-latest-oci.tar \
     containers-storage:greengrass-lite-2layer:v5
   
   # x86-64
   skopeo copy oci-archive:tmp-vruntime-x86-64/deploy/images/qemux86-64/greengrass-lite-2layer-latest-oci.tar \
     containers-storage:greengrass-lite-2layer:v5-amd64
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

2. **Pull the image:**
   ```bash
   docker pull ghcr.io/thomas-roos/greengrass-lite:latest
   # or
   podman pull ghcr.io/thomas-roos/greengrass-lite:latest
   ```

3. **Setup with your connection kit:**
   ```bash
   ./setup.sh connectionKit.zip
   echo "nameserver 8.8.8.8" > ./volumes/resolv.conf
   ```

4. **Update compose.yaml to use the registry image:**
   ```bash
   sed -i 's|image:.*|image: ghcr.io/thomas-roos/greengrass-lite:latest|' compose.yaml
   ```

5. **Start container:**
   ```bash
   docker-compose up -d
   # or for podman
   podman-compose up -d
   ```

## Architecture

**2-Layer Design:**
- **Layer 1 (54MB):** systemd + base system + usrmerge-compat
- **Layer 2 (32MB):** Greengrass Lite + services

**Benefits:**
- Base layer rarely changes, efficient updates
- Application layer updates are small (32MB)
- Shared base across multiple containers

## Configuration

**Volumes:**
- `./volumes/etc-greengrass` - Certificates and config
- `./volumes/var-lib-greengrass` - Runtime data

**Connection Kit:**
The `setup.sh` script extracts your AWS IoT connection kit and configures:
- Device certificates
- Private key (with correct permissions for ggcore user)
- Root CA certificate
- config.yaml with NucleusLite component

## Container Runtime

**Docker and Podman both supported:**
```bash
docker compose up -d
# or
podman compose up -d
```

**Key requirement:** Use `--privileged` mode for systemd to manage cgroups properly.

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

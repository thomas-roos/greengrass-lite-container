# Greengrass Lite Container

Multi-layer OCI container with AWS Greengrass Lite and systemd, built using Yocto and meta-virtualization.

## Quick Start

1. **Build the image:**
   ```bash
   bitbake-setup init
   . ./bitbake-builds/bitbake-setup-greengrass-lite-container-distro_poky-machine_qemuarm64/build/init-build-env
   bitbake greengrass-lite-2layer
   ```

2. **Load to Podman:**
   ```bash
   skopeo copy oci-archive:tmp/deploy/images/qemuarm64/greengrass-lite-2layer-latest-oci.tar \
     containers-storage:greengrass-lite-2layer:v5
   ```

3. **Setup with your AWS IoT connection kit:**
   ```bash
   ./setup.sh connectionKit.zip
   ```

4. **Start container:**
   ```bash
   podman compose up -d
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

**Podman (Recommended):**
```bash
podman compose up -d
```

**Docker:**
May have systemd initialization issues. Use Podman for production.

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

# Registry Push Guide

## Quick Push to Registry

The built OCI image can be pushed directly to any OCI-compliant registry using the included script:

```bash
./meta-application/scripts/push-to-registry.sh \
  <oci-image-path> \
  <registry-url> \
  [image-name] \
  [tag]
```

## Examples

### Docker Hub
```bash
export REGISTRY_USER=myusername
export REGISTRY_PASS=mypassword
./meta-application/scripts/push-to-registry.sh \
  ./bitbake-builds/bitbake-setup-greengrass-lite-container-distro_poky-machine_qemuarm64/build/tmp/deploy/images/qemuarm64/greengrass-lite-container-latest-oci.tar \
  docker.io/myusername
```

### AWS ECR
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

# Push
export REGISTRY_USER=AWS
export REGISTRY_PASS=$(aws ecr get-login-password --region us-east-1)
./meta-application/scripts/push-to-registry.sh \
  ./bitbake-builds/.../greengrass-lite-container-latest-oci.tar \
  123456789.dkr.ecr.us-east-1.amazonaws.com
```

### Private Registry
```bash
./meta-application/scripts/push-to-registry.sh \
  ./bitbake-builds/.../greengrass-lite-container-latest-oci.tar \
  registry.example.com:5000 \
  greengrass-lite \
  v1.0.0
```

## Manual Push with Skopeo

```bash
# Install skopeo
sudo apt-get install skopeo

# Push to registry
skopeo copy \
  --dest-creds username:password \
  oci-archive:/path/to/greengrass-lite-container-latest-oci.tar \
  docker://registry.example.com/greengrass-lite:latest
```

## Load to Local Docker

```bash
skopeo copy \
  oci-archive:/path/to/greengrass-lite-container-latest-oci.tar \
  docker-daemon:greengrass-lite-container:latest
```

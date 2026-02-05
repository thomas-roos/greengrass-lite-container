# Multi-Layer Greengrass Lite Container - Status Report

## ✅ Successfully Implemented

### Based on meta-aws-demos Best Practices
Applied patterns from [aws4embeddedlinux/meta-aws-demos](https://github.com/aws4embeddedlinux/meta-aws-demos/tree/master-next/meta-aws-demos/recipes-core/images/aws-iot-greengrass-lite-container-demo-image):

1. **Minimal SystemD Base Layer** (`greengrass-lite-base`)
   - Uses `base-files`, `base-passwd`, `netbase`, `busybox`
   - SystemD with unified cgroup hierarchy
   - Disabled unnecessary systemd features (resolved, networkd)
   - Size: **45.3 MB** (compressed)

2. **Application Layer** (`greengrass-lite-container`)
   - Builds on top of base layer using `OCI_BASE_IMAGE`
   - Adds only `greengrass-lite` package
   - Size: **26.3 MB** (compressed)
   - **Total multi-layer size: 71.6 MB**

3. **Build System**
   - Successfully builds both layers with BitBake
   - Proper OCI format output
   - Can be loaded to Docker with skopeo

## 🔍 Current Issue: Entrypoint Inheritance

### Problem
When using `OCI_BASE_IMAGE` pattern, the application layer does not inherit the entrypoint from the base layer:

```bash
# Base layer has correct entrypoint
OCI_IMAGE_ENTRYPOINT = "/sbin/init systemd.unified_cgroup_hierarchy=1"

# Application layer sets same entrypoint
OCI_IMAGE_ENTRYPOINT = "/sbin/init systemd.unified_cgroup_hierarchy=1"

# But Docker shows:
$ docker inspect greengrass-lite-container:latest | jq '.[0].Config.Entrypoint'
["sh"]  # ❌ Wrong - defaults to "sh"
```

### Root Cause
The `image-oci.bbclass` has `OCI_IMAGE_ENTRYPOINT ?= "sh"` as default. When building a multi-layer image with `OCI_BASE_IMAGE`, the entrypoint configuration may not be properly merged or inherited from the base layer.

## 📊 Comparison: Single vs Multi-Layer

| Aspect | Single Layer (greengrass-lite-simple) | Multi-Layer (base + container) |
|--------|--------------------------------------|--------------------------------|
| **Total Size** | 56.8 MB | 71.6 MB |
| **Base Reusability** | ❌ No | ✅ Yes - base can be shared |
| **Build Time** | Faster (single build) | Slower (two builds) |
| **Entrypoint** | ✅ Works | ❌ Not inherited |
| **Layer Separation** | ❌ Monolithic | ✅ Clean separation |
| **Update Efficiency** | Full rebuild | Only app layer rebuild |

## 🎯 Solutions to Explore

### Option 1: Override Entrypoint at Runtime
```bash
docker run -d --name greengrass-lite \
  --entrypoint /sbin/init \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --cap-add SYS_ADMIN \
  --security-opt seccomp=unconfined \
  --tmpfs /run --tmpfs /run/lock \
  greengrass-lite-container:latest \
  systemd.unified_cgroup_hierarchy=1
```

### Option 2: Use Single-Layer for Now
The `greengrass-lite-simple` image works correctly and is smaller. Use this until multi-layer entrypoint inheritance is resolved.

### Option 3: Investigate image-oci.bbclass
The `OCI_BASE_IMAGE` feature may need enhancement to properly merge OCI config from base layer. This would require:
- Understanding umoci's layer merging behavior
- Potentially patching image-oci.bbclass or image-oci-umoci.inc
- Testing with explicit config merging

### Option 4: Post-Build OCI Manipulation
Use `umoci` or `skopeo` to modify the OCI image config after build:
```bash
umoci config --image oci:greengrass-lite-container:latest \
  --config.entrypoint="/sbin/init" \
  --config.cmd="systemd.unified_cgroup_hierarchy=1"
```

## 📝 Key Learnings from meta-aws-demos

1. **Minimal Package Selection**: Use `base-files`, `base-passwd`, `netbase`, `busybox` instead of `packagegroup-core-boot`
2. **SystemD Configuration**: Disable features at build time with `PACKAGECONFIG:pn-systemd:remove` rather than masking services
3. **Container Optimization**: Set `IMAGE_CONTAINER_NO_DUMMY = "1"` and `NO_RECOMMENDATIONS = "1"`
4. **Service Management**: Use `systemctl --root="${IMAGE_ROOTFS}"` in ROOTFS_POSTPROCESS_COMMAND

## 🚀 Recommended Next Steps

1. **Short-term**: Use `greengrass-lite-simple` single-layer image (works, smaller, simpler)
2. **Medium-term**: Override entrypoint at runtime for multi-layer deployment
3. **Long-term**: Contribute fix to meta-virtualization for proper OCI_BASE_IMAGE entrypoint inheritance

## 📦 Built Artifacts

All images available at:
```
/home/ubuntu/data/greengrass-lite-container/bitbake-builds/bitbake-setup-greengrass-lite-container-distro_poky-machine_qemuarm64/build/tmp/deploy/images/qemuarm64/
```

- `greengrass-lite-base-*.rootfs-oci/` - Base layer OCI directory
- `greengrass-lite-container-*.rootfs-oci/` - Application layer OCI directory  
- `greengrass-lite-simple-*.rootfs-oci/` - Working single-layer image

## ✅ What Works Right Now

```bash
# Load single-layer image (RECOMMENDED)
skopeo copy oci:/path/to/greengrass-lite-simple-*.rootfs-oci \
  docker-daemon:greengrass-lite:latest

# Run with proper configuration
docker run -d --name greengrass-lite \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --cap-add SYS_ADMIN \
  --security-opt seccomp=unconfined \
  --tmpfs /run --tmpfs /run/lock \
  -v /path/to/etc-greengrass:/etc/greengrass \
  -v /path/to/var-lib-greengrass:/var/lib/greengrass \
  greengrass-lite:latest
```

Container will start SystemD and wait for Greengrass configuration.

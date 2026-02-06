# 2-Layer Greengrass Lite Container - Analysis

## Goal
Split SystemD and Greengrass Lite into separate OCI layers for:
- Independent layer caching
- Smaller updates (only greengrass layer changes)
- Clear separation of concerns

## Attempts Made

### Attempt 1: OCI_LAYERS with 4 layers
```bitbake
OCI_LAYERS = "\
    base:packages:base-files+base-passwd+netbase \
    shell:packages:busybox \
    systemd:packages:systemd+libcgroup+ca-certificates \
    app:packages:greengrass-lite \
"
```
**Result**: ❌ Layers created but runtime path mismatch (/sbin/init vs /usr/sbin/init)

### Attempt 2: OCI_LAYERS with 2 layers
```bitbake
OCI_LAYERS = "\
    systemd:packages:base-files+base-passwd+netbase+busybox+systemd+libcgroup+ca-certificates \
    greengrass:packages:greengrass-lite \
"
```
**Result**: ❌ Same issue - files in /usr/bin but Docker expects /bin

### Attempt 3: Add usrmerge symlinks via ROOTFS_POSTPROCESS_COMMAND
```bitbake
create_compat_symlinks() {
    cd ${IMAGE_ROOTFS}
    ln -sf usr/bin bin
    ln -sf usr/sbin sbin
}
ROOTFS_POSTPROCESS_COMMAND += "create_compat_symlinks; "
```
**Result**: ❌ IMAGE_ROOTFS not used in OCI_LAYERS mode - symlinks not created

## Root Cause

The OCI_LAYERS feature in meta-virtualization:
1. ✅ Creates separate layer directories correctly
2. ✅ Installs packages to each layer using dnf/rpm
3. ✅ Generates OCI blobs from each layer
4. ❌ **Does NOT handle usrmerge** - files stay in /usr/bin, /usr/sbin
5. ❌ **Does NOT create compatibility symlinks** between layers

Modern Yocto uses usrmerge by default:
- Binaries go to `/usr/bin` and `/usr/sbin`
- Symlinks `/bin → /usr/bin` and `/sbin → /usr/sbin` provide compatibility
- These symlinks must be in the FIRST layer for Docker to find them

## Why It Fails

```
Layer 1 (systemd):
  /usr/bin/busybox  ✅ exists
  /usr/sbin/init    ✅ exists
  /bin → /usr/bin   ❌ missing
  /sbin → /usr/sbin ❌ missing

Docker tries to run:
  /usr/bin/sh       ❌ not found (no /bin/sh symlink)
  /usr/sbin/init    ❌ not found (no /sbin/init symlink)
```

## Possible Solutions

### Solution 1: Create a base-compat package
Create a minimal package that only provides symlinks:
```bitbake
# recipes-core/base-compat/base-compat_1.0.bb
do_install() {
    install -d ${D}
    ln -sf usr/bin ${D}/bin
    ln -sf usr/sbin ${D}/sbin
    ln -sf usr/lib ${D}/lib
}

# Then in OCI_LAYERS:
OCI_LAYERS = "\
    compat:packages:base-compat \
    systemd:packages:base-files+busybox+systemd \
    greengrass:packages:greengrass-lite \
"
```

### Solution 2: Patch OCI_LAYERS to add symlinks
Modify `image-oci-umoci.inc` to automatically create usrmerge symlinks in layer-1.

### Solution 3: Use absolute paths everywhere
```bitbake
OCI_IMAGE_ENTRYPOINT = "/usr/bin/sh"
OCI_IMAGE_CMD = "-c 'exec /usr/sbin/init'"
```
**Issue**: Still fails because Docker's default shell is `/bin/sh`

### Solution 4: Use single-layer (RECOMMENDED)
The single-layer approach works perfectly because:
- All files and symlinks are in one layer
- No cross-layer path resolution needed
- Smaller total size (56.8 MB vs 84 MB)
- Production-tested in meta-aws-demos

## Recommendation

**Use `greengrass-lite-simple` single-layer image** until:
1. meta-virtualization adds usrmerge support to OCI_LAYERS, OR
2. We create a base-compat package for symlinks, OR
3. Yocto provides a standard way to handle this

## Layer Sizes Comparison

| Approach | Layer 1 | Layer 2 | Total | Works |
|----------|---------|---------|-------|-------|
| **Single-layer** | 56.8 MB | - | 56.8 MB | ✅ Yes |
| **2-layer (OCI_LAYERS)** | 52.5 MB | 31.5 MB | 84 MB | ❌ No |
| **2-layer (OCI_BASE_IMAGE)** | 45.3 MB | 26.3 MB | 71.6 MB | ❌ No |

## Conclusion

The 2-layer split is **architecturally sound** but requires usrmerge compatibility that the current OCI_LAYERS implementation doesn't provide. The single-layer approach is the pragmatic solution for production use.

**Status**: Documented limitation - use single-layer for now ✅

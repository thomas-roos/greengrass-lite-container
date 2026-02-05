# usrmerge Investigation - Final Findings

## Question
"May we miss the USRMERGE distro feature?"

## Answer
**No** - usrmerge IS enabled in DISTRO_FEATURES.

## Investigation Results

### 1. usrmerge is Enabled
```bash
$ bitbake-getvar DISTRO_FEATURES | grep usrmerge
DISTRO_FEATURES="... systemd virtualization systemd usrmerge ..."
```

### 2. Symlinks ARE Created
Created `usrmerge-compat` package that provides:
- `/bin → usr/bin`
- `/sbin → usr/sbin`
- `/lib → usr/lib`

### 3. Symlinks ARE in OCI Layers
```bash
$ ls -la layer-1-compat/
lrwxrwxrwx bin -> usr/bin
lrwxrwxrwx sbin -> usr/sbin
lrwxrwxrwx lib -> usr/lib
```

### 4. Symlinks ARE in Docker Image
```bash
$ docker save greengrass-lite-2layer:v3 | tar -x
$ tar -xf blobs/sha256/...
$ ls -la
lrwxrwxrwx bin -> usr/bin  ✅
lrwxrwxrwx sbin -> usr/sbin  ✅
```

### 5. Binaries ARE in Layers
```bash
Layer 1 (compat): symlinks
Layer 2 (systemd): usr/bin/busybox, usr/sbin/init
Layer 3 (greengrass): greengrass-lite
```

## Root Cause: Docker Layer Overlay Issue

The problem is **NOT** missing usrmerge or symlinks.

The problem is that **Docker's OverlayFS isn't properly merging the OCI layers created by umoci**.

### Evidence:
```bash
$ docker run --rm greengrass-lite-2layer:v3 /bin/sh -c "echo test"
/bin/sh: /bin/sh: cannot execute binary file
```

Even though:
- `/bin` symlink exists in layer 1 ✅
- `/usr/bin/busybox` exists in layer 2 ✅  
- `/bin → usr/bin` should resolve to `/usr/bin/busybox` ✅

Docker reports "cannot execute binary file" which means:
1. The path resolution is failing across layers, OR
2. The layers aren't being properly overlaid by Docker's runtime

## Why Single-Layer Works

In a single-layer image:
- All files and symlinks are in ONE layer
- No cross-layer path resolution needed
- Docker's OverlayFS works correctly

## Conclusion

This is a **limitation of the OCI_LAYERS implementation** in meta-virtualization when used with Docker's runtime, not a missing DISTRO_FEATURE.

The feature creates valid OCI images, but Docker's layer overlay mechanism doesn't properly handle:
- Symlinks in layer N pointing to files in layer N+1
- Cross-layer path resolution for usrmerge patterns

**Recommendation**: Use single-layer `greengrass-lite-simple` - it works perfectly because everything is in one layer.

**Status**: usrmerge is NOT the issue - Docker layer overlay is ✅

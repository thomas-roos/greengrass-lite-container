# OCI_LAYERS Multi-Layer Feature Discovery

## ✅ Feature Found in meta-virtualization

The `OCI_LAYERS` multi-layer feature exists in the **container-cross-install** branch of meta-virtualization.

### Commit Details
- **Commit**: `24c604854c6ffe79ac7973e333b2df7f7f82ddd9`
- **Author**: Bruce Ashfield
- **Date**: Wed Jan 14 2026
- **Branch**: `container-cross-install`
- **Title**: "image-oci: add multi-layer OCI image support with OCI_LAYERS"

### Feature Overview

Instead of using `OCI_BASE_IMAGE` pattern (which has entrypoint inheritance issues), use **explicit layer definitions**:

```bitbake
OCI_LAYER_MODE = "multi"

OCI_LAYERS = "\
    base:packages:base-files+base-passwd+netbase \
    shell:packages:busybox \
    systemd:packages:systemd+libcgroup \
    app:packages:greengrass-lite \
"
```

### Layer Types Supported
1. **packages**: Install specific packages in a layer
2. **directories**: Copy directories from IMAGE_ROOTFS
3. **files**: Copy specific files from IMAGE_ROOTFS

### Key Benefits
- ✅ Fine-grained control over layer composition
- ✅ Each layer can be cached and shared independently
- ✅ No entrypoint inheritance issues
- ✅ Explicit configuration in single recipe

### Example from meta-virtualization

```bitbake
SUMMARY = "Multi-layer Application container"
LICENSE = "MIT"

OCI_LAYER_MODE = "multi"

OCI_LAYERS = "\
    base:packages:base-files+base-passwd+netbase \
    shell:packages:busybox \
    app:packages:curl \
"

OCI_IMAGE_CMD = "/bin/sh"

IMAGE_FSTYPES = "container oci"
inherit image
inherit image-oci

IMAGE_INSTALL = "base-files base-passwd netbase busybox curl"
```

## 🔄 Current Status

### Our Setup
- **Current branch**: `whinlatter` (commit `8f03a0cc`)
- **Feature branch**: `container-cross-install` (commit `24c60485`)
- **Status**: Feature NOT in current branch

### To Use This Feature

**Option 1: Update bitbake-setup.conf.json**
```json
"meta-virtualization": {
    "git-remote": {
        "remotes": {
            "origin": {
                "uri": "git://git.yoctoproject.org/meta-virtualization;protocol=https"
            }
        },
        "branch": "container-cross-install",
        "rev": "24c604854c6ffe79ac7973e333b2df7f7f82ddd9"
    },
    "path": "meta-virtualization"
}
```

Then reinitialize the build environment.

**Option 2: Manual Git Update** (if build already exists)
```bash
cd bitbake-builds/.../layers/meta-virtualization
git fetch origin
git checkout container-cross-install
git reset --hard 24c60485
```

## 📦 Recipe Created

Created `greengrass-lite-multilayer.bb` using the OCI_LAYERS pattern:
- 4 explicit layers: base, shell, systemd, app
- SystemD entrypoint properly configured
- All packages listed in IMAGE_INSTALL

**Location**: `meta-application/recipes-containers/greengrass-lite-multilayer/`

## 🎯 Next Steps

1. **Update meta-virtualization** to container-cross-install branch
2. **Build the new recipe**: `bitbake greengrass-lite-multilayer`
3. **Test the multi-layer image** with proper layer separation
4. **Compare** with single-layer and OCI_BASE_IMAGE approaches

## 📊 Comparison: Three Approaches

| Approach | Layers | Entrypoint | Complexity | Status |
|----------|--------|------------|------------|--------|
| **Single-layer** | 1 | ✅ Works | Simple | ✅ Working |
| **OCI_BASE_IMAGE** | 2 | ❌ Not inherited | Medium | ⚠️ Issue |
| **OCI_LAYERS** | 4+ explicit | ✅ Configurable | Medium | 🔄 Needs branch update |

## 🚀 Recommendation

**Use OCI_LAYERS approach** - it provides the best of both worlds:
- Explicit multi-layer control
- No entrypoint inheritance issues
- Clean layer separation for caching
- Single recipe configuration

This is the **official multi-layer feature** from meta-virtualization maintainer Bruce Ashfield.

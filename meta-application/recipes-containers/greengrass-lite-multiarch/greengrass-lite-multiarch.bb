SUMMARY = "Greengrass Lite 2-layer container - Multi-arch build"
DESCRIPTION = "Builds ARM64 and x86-64 versions using BBMULTICONFIG"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

# This is a meta-recipe that triggers multiconfig builds
# It doesn't produce an image itself, just coordinates the builds

# Build both architectures
BBMULTICONFIG = "vruntime-aarch64 vruntime-x86-64"

# Depend on the actual image recipe for both architectures
do_build[mcdepends] = "mc:vruntime-aarch64::greengrass-lite-2layer:do_image_complete"
do_build[mcdepends] += "mc:vruntime-x86-64::greengrass-lite-2layer:do_image_complete"

# No actual build steps
do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

python do_build() {
    bb.note("Multi-arch build complete")
    bb.note("ARM64: tmp-vruntime-aarch64/deploy/images/qemuarm64/")
    bb.note("x86-64: tmp-vruntime-x86-64/deploy/images/qemux86-64/")
}

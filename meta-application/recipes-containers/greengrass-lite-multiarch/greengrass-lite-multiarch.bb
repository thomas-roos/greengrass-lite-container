SUMMARY = "Greengrass Lite 2-layer container - Multi-arch build"
DESCRIPTION = "Builds ARM64 and x86-64 versions using oci-multiarch class"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit oci-multiarch

OCI_MULTIARCH_RECIPE = "greengrass-lite-2layer"
OCI_MULTIARCH_PLATFORMS = "aarch64 x86_64"

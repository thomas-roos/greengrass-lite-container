SUMMARY = "Greengrass Lite Multi-Layer Container using OCI_LAYERS"
DESCRIPTION = "Multi-layer OCI image with explicit layer definitions"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

# Enable multi-layer mode with explicit layer definitions
OCI_LAYER_MODE = "multi"

# Define 2 layers: systemd base and greengrass app
OCI_LAYERS = "\
    systemd:packages:base-files+base-passwd+netbase+busybox+systemd+libcgroup+ca-certificates \
    greengrass:packages:greengrass-lite \
"

# SystemD entrypoint - use /usr/sbin/init (actual location)
OCI_IMAGE_ENTRYPOINT = "/usr/sbin/init"
OCI_IMAGE_CMD = "systemd.unified_cgroup_hierarchy=1"

IMAGE_FSTYPES = "container oci"
inherit image
inherit image-oci

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"

# List all packages to ensure they're built
IMAGE_INSTALL = "\
    base-files \
    base-passwd \
    netbase \
    busybox \
    systemd \
    libcgroup \
    ca-certificates \
    greengrass-lite \
"

# Disable fleet provisioning
PACKAGECONFIG:pn-greengrass-lite = ""

# Disable unnecessary systemd features
PACKAGECONFIG:pn-systemd:remove = "resolved networkd"

IMAGE_CONTAINER_NO_DUMMY = "1"

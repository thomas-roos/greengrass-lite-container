SUMMARY = "Greengrass Lite Base Layer - SystemD container base"
DESCRIPTION = "A minimal systemd system container base layer for Greengrass Lite"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

IMAGE_FSTYPES = "container oci"
inherit image
inherit image-oci

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"

IMAGE_INSTALL = " \
    base-files \
    base-passwd \
    netbase \
    busybox \
    systemd \
    systemd-serialgetty \
    libcgroup \
    ca-certificates \
"

# SystemD as init
OCI_IMAGE_ENTRYPOINT = "/sbin/init systemd.unified_cgroup_hierarchy=1"
OCI_IMAGE_AUTHOR = "Greengrass Lite Container"
OCI_IMAGE_TAG = "base"

# Disable unnecessary systemd features for containers
PACKAGECONFIG:pn-systemd:remove = "resolved networkd"

# Minimal rootfs
IMAGE_CONTAINER_NO_DUMMY = "1"
CONTAINER_BUNDLE_DEPLOY = "1"

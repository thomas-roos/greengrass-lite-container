SUMMARY = "Greengrass Lite Container - Single layer for testing"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

IMAGE_FSTYPES = "container oci"
inherit core-image
inherit image-oci

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"

IMAGE_INSTALL = " \
    packagegroup-core-boot \
    systemd \
    greengrass-lite \
    ca-certificates \
    openssl \
    curl \
"

OCI_IMAGE_ENTRYPOINT = "/sbin/init"
IMAGE_CONTAINER_NO_DUMMY = "1"

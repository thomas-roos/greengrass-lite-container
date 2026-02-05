SUMMARY = "Greengrass Lite Container - Application layer"
DESCRIPTION = "Multi-layer OCI image with AWS Greengrass Lite on systemd base"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

# Use greengrass-lite-base as the base layer
OCI_BASE_IMAGE = "greengrass-lite-base"

IMAGE_FSTYPES = "container oci"
inherit image
inherit image-oci

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"

# Add Greengrass Lite on top of base layer
IMAGE_INSTALL = " \
    greengrass-lite \
"

# Inherit entrypoint from base layer
OCI_IMAGE_ENTRYPOINT = "/sbin/init systemd.unified_cgroup_hierarchy=1"
OCI_IMAGE_TAG = "latest"

# Disable fleet provisioning (requires manual config)
PACKAGECONFIG:pn-greengrass-lite = ""

# Enable greengrass-lite.target
SERVICES_TO_ENABLE = "greengrass-lite.target"

enable_systemd_services() {
    for service in ${SERVICES_TO_ENABLE}; do
        if [ -f ${IMAGE_ROOTFS}/lib/systemd/system/$service ] || [ -f ${IMAGE_ROOTFS}/etc/systemd/system/$service ]; then
            systemctl --root="${IMAGE_ROOTFS}" enable $service || true
        fi
    done
}

ROOTFS_POSTPROCESS_COMMAND += "enable_systemd_services; "

IMAGE_CONTAINER_NO_DUMMY = "1"

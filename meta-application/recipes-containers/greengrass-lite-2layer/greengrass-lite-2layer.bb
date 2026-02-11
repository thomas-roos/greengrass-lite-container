SUMMARY = "Greengrass Lite 2-Layer: Base + Greengrass v50"
DESCRIPTION = "Multi-layer OCI with base (systemd+containers) and greengrass-lite in separate layers"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

# for now no cache to make sure everything is up to date
OCI_LAYER_CACHE = "0"

# Enable multi-layer mode
OCI_LAYER_MODE = "multi"

# Each package in its own layer - last layer overlays on top
OCI_LAYERS = "\
    base:packages:usrmerge-compat+base-files+base-passwd+netbase \
    libcgroup:packages:libcgroup \
    ca-certificates:packages:ca-certificates \
    iptables:packages:iptables \
    slirp4netns:packages:slirp4netns \
    python3:packages:python3-misc+python3-venv+python3-tomllib+python3-ensurepip+python3-pip \
    iputils:packages:iputils-ping \
    crun:packages:crun \
    podman:packages:podman \
    systemd:packages:systemd+systemd-serialgetty \
    greengrass-lite:packages:greengrass-lite \
    cleanup:directories:${THISDIR}/${PN}/cleanup-layer \
"

# Use standard paths with usrmerge
OCI_IMAGE_ENTRYPOINT = "/entrypoint.sh"
OCI_IMAGE_CMD = ""
OCI_IMAGE_LABELS = "org.opencontainers.image.source=https://github.com/thomas-roos/greengrass-lite-container"

IMAGE_FSTYPES = "container oci"
inherit image
inherit image-oci

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"

# Remove resolv.conf so OCI runtime can bind mount it
# Use whiteout to hide it from earlier layers
ROOTFS_POSTPROCESS_COMMAND += "remove_resolv_conf; "

remove_resolv_conf() {
    rm -f ${IMAGE_ROOTFS}/etc/resolv.conf
    rm -f ${IMAGE_ROOTFS}/etc/resolv-conf.systemd
    # Create OCI whiteout marker to hide file from lower layers
    touch ${IMAGE_ROOTFS}/etc/.wh.resolv.conf
}

IMAGE_INSTALL = "\
    usrmerge-compat \
    base-files \
    base-passwd \
    netbase \
    systemd \
    systemd-serialgetty \
    libcgroup \
    ca-certificates \
    greengrass-lite \
    podman \
    iptables \
    slirp4netns \
    python3-misc \
    python3-venv \
    python3-tomllib \
    python3-ensurepip \
    python3-pip \
    iputils-ping \
    crun \
"

PACKAGECONFIG:pn-greengrass-lite = ""
PACKAGECONFIG:pn-systemd:remove = "resolved networkd"

# Prevent systemd from creating resolv.conf alternative
ALTERNATIVE:pn-systemd:remove = "resolv-conf"

# Exclude runc, use crun instead
BAD_RECOMMENDATIONS += "runc"

IMAGE_CONTAINER_NO_DUMMY = "1"

# Remove resolv.conf from OCI image after creation
do_image_oci:append() {
    # Find the latest OCI directory
    OCI_DIR="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.rootfs-oci"
    
    if [ -d "$OCI_DIR" ]; then
        # Find and patch each layer blob that contains resolv.conf
        for blob in "$OCI_DIR"/blobs/sha256/*; do
            if tar -tzf "$blob" 2>/dev/null | grep -q "^etc/resolv"; then
                bbnote "Removing resolv.conf from OCI layer $(basename $blob)"
                
                # Extract, remove resolv.conf, repack
                TEMP_DIR=$(mktemp -d)
                tar -xzf "$blob" -C "$TEMP_DIR"
                rm -f "$TEMP_DIR/etc/resolv.conf" "$TEMP_DIR/etc/resolv-conf.systemd"
                tar -czf "$blob" -C "$TEMP_DIR" .
                rm -rf "$TEMP_DIR"
            fi
        done
    fi
}

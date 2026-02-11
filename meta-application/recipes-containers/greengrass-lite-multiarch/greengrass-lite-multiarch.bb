SUMMARY = "Greengrass Lite 2-layer container - Multi-arch build"
DESCRIPTION = "Builds ARM64 and x86-64 versions using oci-multiarch class"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit oci-multiarch

OCI_MULTIARCH_RECIPE = "greengrass-lite-2layer"
OCI_MULTIARCH_PLATFORMS = "aarch64 x86_64"

# Remove resolv.conf from multiarch OCI blobs
do_create_multiarch_index[postfuncs] += "remove_resolv_from_multiarch_blobs"

remove_resolv_from_multiarch_blobs() {
    OCI_DIR="${DEPLOY_DIR_IMAGE}/${PN}-multiarch-oci"
    
    if [ -d "$OCI_DIR" ]; then
        bbnote "Patching multiarch OCI directory: $OCI_DIR"
        for blob in "$OCI_DIR"/blobs/sha256/*; do
            if tar -tzf "$blob" 2>/dev/null | grep -q "^etc/resolv"; then
                bbnote "Removing resolv.conf from multiarch blob $(basename $blob)"
                
                TEMP_DIR=$(mktemp -d)
                tar -xzf "$blob" -C "$TEMP_DIR"
                rm -f "$TEMP_DIR/etc/resolv.conf" "$TEMP_DIR/etc/resolv-conf.systemd"
                tar -czf "$blob" -C "$TEMP_DIR" .
                rm -rf "$TEMP_DIR"
            fi
        done
    fi
}

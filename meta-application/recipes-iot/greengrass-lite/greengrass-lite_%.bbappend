FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    # Configure Greengrass to run components as root instead of ggcore
    if [ -f ${D}${sysconfdir}/greengrass/config.d/greengrass-lite.yaml ]; then
        sed -i 's/@GG_USER@:@GG_GROUP@/root:root/' ${D}${sysconfdir}/greengrass/config.d/greengrass-lite.yaml
    fi
}

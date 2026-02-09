FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    # Ensure ggcore home directory exists with correct permissions
    install -d -m 0755 ${D}/home/ggcore
    
    # Create .config directory for ggcore user (for nested container configs)
    install -d -m 0755 ${D}/home/ggcore/.config
    
    # Set ownership (will be applied at runtime)
    chown -R ggcore:ggcore ${D}/home/ggcore || true
    
    # Configure Greengrass to run components as root instead of ggcore
    if [ -f ${D}${sysconfdir}/greengrass/config.d/greengrass-lite.yaml ]; then
        sed -i 's/runWithDefault:/runWithDefault:\n    posixUser: "root:root"/' ${D}${sysconfdir}/greengrass/config.d/greengrass-lite.yaml
    fi
}

FILES:${PN} += "/home/ggcore /home/ggcore/.config"

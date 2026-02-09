FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    # Ensure ggcore home directory exists with correct permissions
    install -d -m 0755 ${D}/home/ggcore
    
    # Create .config directory for ggcore user (for nested container configs)
    install -d -m 0755 ${D}/home/ggcore/.config
    
    # Set ownership (will be applied at runtime)
    chown -R ggcore:ggcore ${D}/home/ggcore || true
}

FILES:${PN} += "/home/ggcore /home/ggcore/.config"

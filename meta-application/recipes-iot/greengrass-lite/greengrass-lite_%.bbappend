FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    # Create .config directory for ggcore user (for nested container configs)
    install -d -m 0755 ${D}/home/ggcore/.config
    chown -R ggcore:ggcore ${D}/home/ggcore/.config || true
}

FILES:${PN} += "/home/ggcore/.config"

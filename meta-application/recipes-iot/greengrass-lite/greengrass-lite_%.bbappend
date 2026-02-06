# Create home directory for ggcore user
do_install:append() {
    install -d -m 0755 ${D}/home/ggcore
    chown ggcore:ggcore ${D}/home/ggcore
}

FILES:${PN} += "/home/ggcore"

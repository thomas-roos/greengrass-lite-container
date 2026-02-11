FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://entrypoint.sh"

FILES:${PN} += "/entrypoint.sh"

do_install:append() {
    # Remove /etc/resolv.conf
    rm -f ${D}${sysconfdir}/resolv.conf ${D}${sysconfdir}/resolv-conf.systemd
    
    # Install entrypoint script
    install -d ${D}/
    install -m 0755 ${UNPACKDIR}/entrypoint.sh ${D}/entrypoint.sh
}


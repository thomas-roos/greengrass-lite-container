FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://entrypoint.sh"

FILES:${PN} += "/entrypoint.sh"

do_install:append() {
    # Remove /etc/resolv.conf and tmpfiles.d entries that create it
    rm -f ${D}${sysconfdir}/resolv.conf ${D}${sysconfdir}/resolv-conf.systemd
    
    # Remove tmpfiles.d entries that create resolv.conf symlink
    sed -i '/resolv\.conf/d' ${D}${exec_prefix}/lib/tmpfiles.d/etc.conf || true
    sed -i '/resolv\.conf/d' ${D}${exec_prefix}/lib/tmpfiles.d/systemd.conf || true
    sed -i '/resolv\.conf/d' ${D}${exec_prefix}/lib/tmpfiles.d/systemd-resolve.conf || true
    
    # Install entrypoint script
    install -d ${D}/
    install -m 0755 ${UNPACKDIR}/entrypoint.sh ${D}/entrypoint.sh
}


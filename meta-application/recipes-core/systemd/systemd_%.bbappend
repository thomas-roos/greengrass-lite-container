FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://entrypoint.sh"

do_install:append() {
    # Remove /etc/resolv.conf
    rm -f ${D}${sysconfdir}/resolv.conf ${D}${sysconfdir}/resolv-conf.systemd
    
    # Create /var/volatile directories
    install -d -m 1777 ${D}${localstatedir}/volatile/tmp
    install -d -m 0755 ${D}${localstatedir}/volatile/log
    
    # Install entrypoint script
    install -d ${D}/
    install -m 0755 ${UNPACKDIR}/entrypoint.sh ${D}/entrypoint.sh
    
    # Mask services
    install -d ${D}${sysconfdir}/systemd/system
    for svc in systemd-udevd.service systemd-resolved.service systemd-hwdb-update.service \
               systemd-modules-load.service systemd-vconsole-setup.service var-volatile.mount; do
        ln -sf /dev/null ${D}${sysconfdir}/systemd/system/$svc
    done
}


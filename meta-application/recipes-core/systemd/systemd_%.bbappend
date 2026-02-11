FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://entrypoint.sh"

do_install:append() {
    # Remove /etc/resolv.conf
    rm -f ${D}${sysconfdir}/resolv.conf ${D}${sysconfdir}/resolv-conf.systemd
    
    # Create /var/volatile directories
    install -d -m 1777 ${D}${localstatedir}/volatile/tmp
    install -d -m 0755 ${D}${localstatedir}/volatile/log
    
    # Install entrypoint script
    install -m 0755 ${WORKDIR}/entrypoint.sh ${D}/entrypoint.sh
    
    # Mask services
    for svc in systemd-udevd.service systemd-resolved.service systemd-hwdb-update.service \
               systemd-modules-load.service systemd-vconsole-setup.service var-volatile.mount; do
        ln -sf /dev/null ${D}${systemd_system_unitdir}/../system/$svc
    done
}


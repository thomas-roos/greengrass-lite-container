FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
    file://containers.conf \
    file://storage.conf \
    file://registries.conf \
    file://policy.json \
    file://subuid \
    file://subgid \
"

do_install:append() {
    # Install container config files
    install -d ${D}${sysconfdir}/containers
    install -m 0644 ${UNPACKDIR}/containers.conf ${D}${sysconfdir}/containers/
    install -m 0644 ${UNPACKDIR}/storage.conf ${D}${sysconfdir}/containers/
    install -m 0644 ${UNPACKDIR}/registries.conf ${D}${sysconfdir}/containers/
    install -m 0644 ${UNPACKDIR}/policy.json ${D}${sysconfdir}/containers/
    
    # Install subuid/subgid
    install -m 0644 ${UNPACKDIR}/subuid ${D}${sysconfdir}/
    install -m 0644 ${UNPACKDIR}/subgid ${D}${sysconfdir}/
}


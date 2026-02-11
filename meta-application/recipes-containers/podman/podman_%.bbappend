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
    install -m 0644 ${WORKDIR}/containers.conf ${D}${sysconfdir}/containers/
    install -m 0644 ${WORKDIR}/storage.conf ${D}${sysconfdir}/containers/
    install -m 0644 ${WORKDIR}/registries.conf ${D}${sysconfdir}/containers/
    install -m 0644 ${WORKDIR}/policy.json ${D}${sysconfdir}/containers/
    
    # Install subuid/subgid
    install -m 0644 ${WORKDIR}/subuid ${D}${sysconfdir}/
    install -m 0644 ${WORKDIR}/subgid ${D}${sysconfdir}/
}


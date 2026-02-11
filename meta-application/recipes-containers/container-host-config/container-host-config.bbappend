FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "\
    file://containers.conf \
    file://storage.conf \
"

do_install:append() {
    install ${UNPACKDIR}/containers.conf ${D}/${sysconfdir}/containers/containers.conf
}

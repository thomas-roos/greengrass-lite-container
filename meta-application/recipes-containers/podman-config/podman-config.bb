SUMMARY = "Podman configuration for nested containers"
DESCRIPTION = "Configures Podman to support running containers inside containers"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit allarch

SRC_URI = "file://containers.conf"

do_install() {
    install -d ${D}${sysconfdir}/containers
    install -m 0644 ${WORKDIR}/sources/containers.conf ${D}${sysconfdir}/containers/containers.conf
}

FILES:${PN} = "${sysconfdir}/containers/containers.conf"

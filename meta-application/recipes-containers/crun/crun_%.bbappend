inherit update-alternatives

PROVIDES += "virtual-runc"
RPROVIDES:${PN} += "virtual-runc"

do_install:append() {
    # Create runc symlink for compatibility
    ln -sf crun ${D}${bindir}/runc
}

ALTERNATIVE:${PN} = "runc"
ALTERNATIVE_TARGET[runc] = "${bindir}/crun"
ALTERNATIVE_LINK_NAME[runc] = "${bindir}/runc"
ALTERNATIVE_PRIORITY = "100"

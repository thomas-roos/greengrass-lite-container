FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://ggcore-passwd \
            file://ggcore-group"

# Add ggcore user to base-passwd
do_install:append() {
    # Add ggcore to passwd if not already there
    if ! grep -q "^ggcore:" ${D}${datadir}/base-passwd/passwd.master; then
        cat ${WORKDIR}/ggcore-passwd >> ${D}${datadir}/base-passwd/passwd.master
    fi
    
    # Add ggcore to group if not already there
    if ! grep -q "^ggcore:" ${D}${datadir}/base-passwd/group.master; then
        cat ${WORKDIR}/ggcore-group >> ${D}${datadir}/base-passwd/group.master
    fi
}

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Add ggcore user to base-passwd
do_install:append() {
    # Add ggcore to passwd if not already there
    if ! grep -q "^ggcore:" ${D}${datadir}/base-passwd/passwd.master; then
        echo "ggcore:x:0:0:Greengrass Core:/root:/bin/sh" >> ${D}${datadir}/base-passwd/passwd.master
    fi
    
    # Add ggcore to group if not already there
    if ! grep -q "^ggcore:" ${D}${datadir}/base-passwd/group.master; then
        echo "ggcore:x:0:" >> ${D}${datadir}/base-passwd/group.master
    fi
    
    # Create /home/ggcore/.config directory
    install -d -m 0755 ${D}/home/ggcore/.config
}

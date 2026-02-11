# Don't create ggcore user - it's already created in base layer with UID=0
USERADD_PARAM:${PN} = ""
GROUPADD_PARAM:${PN} = ""

# Ensure ggcore user exists (from base layer)
RDEPENDS:${PN} += "base-passwd"

# Patch passwd/group files to ensure ggcore has UID=0
do_install:append() {
    # If package creates passwd/group files, patch them
    if [ -f ${D}${sysconfdir}/passwd ]; then
        sed -i '/^ggcore:/d' ${D}${sysconfdir}/passwd
        echo "ggcore:x:0:0:root:/root:/bin/sh" >> ${D}${sysconfdir}/passwd
    fi
    
    if [ -f ${D}${sysconfdir}/group ]; then
        sed -i '/^ggcore:/d' ${D}${sysconfdir}/group
        echo "ggcore:x:0:" >> ${D}${sysconfdir}/group
    fi
}

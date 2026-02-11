# Don't create ggcore user - it's already created in base layer with UID=0
# Provide dummy values since recipe inherits useradd
USERADD_PARAM:${PN} = "-r -s /bin/false -d /nonexistent dummy"
GROUPADD_PARAM:${PN} = "-r dummy"

# Remove the dummy user/group after install
do_install:append() {
    # Remove dummy entries if they were added
    if [ -f ${D}${sysconfdir}/passwd ]; then
        sed -i '/^dummy:/d' ${D}${sysconfdir}/passwd
    fi
    if [ -f ${D}${sysconfdir}/group ]; then
        sed -i '/^dummy:/d' ${D}${sysconfdir}/group
    fi
}

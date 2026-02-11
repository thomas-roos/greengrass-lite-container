# Add ggcore user with UID=0 to base-passwd
do_install:append() {
    echo "ggcore:x:0:0:Greengrass Core:/root:/bin/sh" >> ${D}${datadir}/base-passwd/passwd.master
    echo "ggcore:x:0:" >> ${D}${datadir}/base-passwd/group.master
}

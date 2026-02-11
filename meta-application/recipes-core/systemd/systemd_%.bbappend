FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Don't create resolv.conf alternative - OCI runtime will bind mount it
ALTERNATIVE:${PN}:remove = "resolv-conf"

# Set OCI container startup command
OCI_IMAGE_CMD:pn-greengrass-lite-2layer = "-c 'mkdir -p /lib64 && ln -sf /lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 2>/dev/null || true; exec /sbin/init systemd.unified_cgroup_hierarchy=1'"

do_install:append() {
    # Remove /etc/resolv.conf symlink and target - OCI runtime will bind mount it
    rm -f ${D}${sysconfdir}/resolv.conf ${D}${sysconfdir}/resolv-conf.systemd
    
    # Remove tmpfiles.d entries that create resolv.conf symlink
    sed -i '/resolv\.conf/d' ${D}${exec_prefix}/lib/tmpfiles.d/etc.conf || true
    sed -i '/resolv\.conf/d' ${D}${exec_prefix}/lib/tmpfiles.d/systemd.conf || true
    sed -i '/resolv\.conf/d' ${D}${exec_prefix}/lib/tmpfiles.d/systemd-resolve.conf || true
    
    # Remove from alternatives system
    rm -f ${D}${libdir}/systemd/resolv.conf
}


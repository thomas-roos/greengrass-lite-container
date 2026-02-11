FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://entrypoint.sh"

# OCI layer postprocess for systemd layer
python oci_layer_postprocess:append() {
    import os
    layer_rootfs = d.getVar('OCI_LAYER_ROOTFS')
    if not layer_rootfs:
        return
    
    # Remove /etc/resolv.conf
    for f in ['etc/resolv.conf', 'etc/resolv-conf.systemd']:
        path = os.path.join(layer_rootfs, f)
        if os.path.exists(path) or os.path.islink(path):
            os.remove(path)
    
    # Create /var/volatile directories
    for d in ['var/volatile/tmp', 'var/volatile/log']:
        path = os.path.join(layer_rootfs, d)
        bb.utils.mkdirhier(path)
        os.chmod(path, 0o1777 if 'tmp' in d else 0o755)
    
    # Install entrypoint script
    entrypoint = os.path.join(layer_rootfs, 'entrypoint.sh')
    bb.utils.copyfile(d.expand('${WORKDIR}/entrypoint.sh'), entrypoint)
    os.chmod(entrypoint, 0o755)
    
    # Mask services
    systemd_dir = os.path.join(layer_rootfs, 'etc/systemd/system')
    bb.utils.mkdirhier(systemd_dir)
    for svc in ['systemd-udevd.service', 'systemd-resolved.service', 'systemd-hwdb-update.service', 
                'systemd-modules-load.service', 'systemd-vconsole-setup.service', 'var-volatile.mount']:
        link = os.path.join(systemd_dir, svc)
        if not os.path.exists(link):
            os.symlink('/dev/null', link)
}

do_image_oci[prefuncs] += "oci_layer_postprocess"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
    file://containers.conf \
    file://storage.conf \
    file://registries.conf \
    file://policy.json \
    file://subuid \
    file://subgid \
"

# OCI layer postprocess for podman layer
python oci_layer_postprocess:append() {
    import os
    layer_rootfs = d.getVar('OCI_LAYER_ROOTFS')
    if not layer_rootfs:
        return
    
    # Install container config files
    etc_containers = os.path.join(layer_rootfs, 'etc/containers')
    bb.utils.mkdirhier(etc_containers)
    for f in ['containers.conf', 'storage.conf', 'registries.conf', 'policy.json']:
        bb.utils.copyfile(d.expand(f'${{WORKDIR}}/{f}'), os.path.join(etc_containers, f))
    
    # Install subuid/subgid
    for f in ['subuid', 'subgid']:
        bb.utils.copyfile(d.expand(f'${{WORKDIR}}/{f}'), os.path.join(layer_rootfs, 'etc', f))
}

do_image_oci[prefuncs] += "oci_layer_postprocess"

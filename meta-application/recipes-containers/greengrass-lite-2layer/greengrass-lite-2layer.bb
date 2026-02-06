SUMMARY = "Greengrass Lite 2-Layer: SystemD Base + Greengrass App"
DESCRIPTION = "Multi-layer OCI with systemd and greengrass-lite in separate layers"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

# Enable multi-layer mode
OCI_LAYER_MODE = "multi"

# 2 layers: systemd base (with usrmerge-compat) + greengrass app
OCI_LAYERS = "\
    systemd:packages:usrmerge-compat+base-files+base-passwd+netbase+systemd+systemd-serialgetty+libcgroup+ca-certificates \
    greengrass:packages:greengrass-lite+podman+iptables \
"

# Use standard paths with usrmerge
OCI_IMAGE_ENTRYPOINT = "/sbin/init"
OCI_IMAGE_CMD = "systemd.unified_cgroup_hierarchy=1"

IMAGE_FSTYPES = "container oci"
inherit image
inherit image-oci

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
NO_RECOMMENDATIONS = "1"

IMAGE_INSTALL = "\
    usrmerge-compat \
    base-files \
    base-passwd \
    netbase \
    systemd \
    systemd-serialgetty \
    libcgroup \
    ca-certificates \
    greengrass-lite \
    podman \
    iptables \
"

PACKAGECONFIG:pn-greengrass-lite = ""
PACKAGECONFIG:pn-systemd:remove = "resolved networkd"

# Python function to fix up OCI layers after package installation
python oci_layer_postprocess() {
    import os
    import subprocess
    
    layer_mode = d.getVar('OCI_LAYER_MODE') or 'single'
    if layer_mode != 'multi':
        return
    
    layer_count = int(d.getVar('OCI_LAYER_COUNT') or '0')
    if layer_count == 0:
        return
    
    bb.note("OCI: Post-processing layers for systemd container")
    
    # Services to disable for containers
    services_to_disable = [
        'systemd-udevd.service',
        'systemd-resolved.service',
        'systemd-hwdb-update.service',
        'systemd-modules-load.service',
        'systemd-vconsole-setup.service',
        'var-volatile.mount',
    ]
    
    # Process each layer
    for layer_num in range(1, layer_count + 1):
        layer_rootfs = d.getVar(f'OCI_LAYER_{layer_num}_ROOTFS')
        layer_name = d.getVar(f'OCI_LAYER_{layer_num}_NAME')
        
        if not layer_rootfs or not os.path.exists(layer_rootfs):
            continue
        
        bb.note(f"OCI: Post-processing layer {layer_num} '{layer_name}'")
        
        # Remove /etc/resolv.conf from ALL layers (let container runtime manage it)
        resolv_conf = os.path.join(layer_rootfs, 'etc/resolv.conf')
        if os.path.exists(resolv_conf) or os.path.islink(resolv_conf):
            os.remove(resolv_conf)
            bb.note(f"OCI: Removed /etc/resolv.conf from layer '{layer_name}'")
        
        # Also remove the target if it's a systemd-managed file
        resolv_systemd = os.path.join(layer_rootfs, 'etc/resolv-conf.systemd')
        if os.path.exists(resolv_systemd):
            os.remove(resolv_systemd)
            bb.note(f"OCI: Removed /etc/resolv-conf.systemd from layer '{layer_name}'")
        
        # Create ggcore home directory in greengrass layer
        if layer_name == 'greengrass':
            ggcore_home = os.path.join(layer_rootfs, 'home/ggcore')
            if not os.path.exists(ggcore_home):
                bb.utils.mkdirhier(ggcore_home)
                os.chmod(ggcore_home, 0o755)
                bb.note(f"OCI: Created /home/ggcore directory in layer '{layer_name}'")
                # Note: Ownership will be set by the ggcore user creation in greengrass-lite package
        
        # Only process systemd layer for other fixes
        if layer_name == 'systemd':
            # Create /var/volatile directories
            volatile_tmp = os.path.join(layer_rootfs, 'var/volatile/tmp')
            volatile_log = os.path.join(layer_rootfs, 'var/volatile/log')
            bb.utils.mkdirhier(volatile_tmp)
            bb.utils.mkdirhier(volatile_log)
            os.chmod(volatile_tmp, 0o1777)
            os.chmod(volatile_log, 0o755)
            bb.note(f"OCI: Created /var/volatile directories in layer '{layer_name}'")
            
            # Mask systemd services by creating symlinks to /dev/null
            systemd_system_dir = os.path.join(layer_rootfs, 'etc/systemd/system')
            bb.utils.mkdirhier(systemd_system_dir)
            
            for service in services_to_disable:
                service_link = os.path.join(systemd_system_dir, service)
                if not os.path.exists(service_link):
                    os.symlink('/dev/null', service_link)
                    bb.note(f"OCI: Masked service {service}")
}

# Run after oci_multilayer_install_packages
do_image_oci[prefuncs] += "oci_layer_postprocess"

IMAGE_CONTAINER_NO_DUMMY = "1"

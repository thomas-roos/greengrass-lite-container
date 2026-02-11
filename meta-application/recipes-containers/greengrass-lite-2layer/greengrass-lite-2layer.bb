SUMMARY = "Greengrass Lite 2-Layer: Base + Greengrass v33"
DESCRIPTION = "Multi-layer OCI with base (systemd+containers) and greengrass-lite in separate layers"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

# Force rootfs and OCI layer rebuild when anything changes
do_rootfs[nostamp] = "1"
do_image_oci[nostamp] = "1"

# Increment this to force rebuild
PR = "r19"

# Enable multi-layer mode
OCI_LAYER_MODE = "multi"

# 2 layers: greengrass (just greengrass-lite) + base (systemd + containers + python)
# Base layer is last so its /etc/passwd with ggcore UID=0 overlays on top
OCI_LAYERS = "\
    greengrass:packages:greengrass-lite \
    base:packages:usrmerge-compat+base-files+base-passwd+netbase+systemd+systemd-serialgetty+libcgroup+ca-certificates+podman+iptables+slirp4netns+python3-misc+python3-venv+python3-tomllib+python3-ensurepip+python3-pip+iputils-ping+crun \
"

# Use standard paths with usrmerge
OCI_IMAGE_ENTRYPOINT = "/entrypoint.sh"
OCI_IMAGE_CMD = ""

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
    slirp4netns \
    python3-misc \
    python3-venv \
    python3-tomllib \
    python3-ensurepip \
    python3-pip \
    iputils-ping \
    crun \
"

PACKAGECONFIG:pn-greengrass-lite = ""
PACKAGECONFIG:pn-systemd:remove = "resolved networkd"

# Exclude runc, use crun instead
BAD_RECOMMENDATIONS += "runc"

# Python function to fix up OCI layers after package installation
python oci_layer_postprocess() {
    import os
    
    layer_mode = d.getVar('OCI_LAYER_MODE') or 'single'
    if layer_mode != 'multi':
        return
    
    layer_count = int(d.getVar('OCI_LAYER_COUNT') or '0')
    if layer_count == 0:
        return
    
    bb.note("OCI: Post-processing layers for multi-layer container")
    
    services_to_disable = [
        'systemd-udevd.service',
        'systemd-resolved.service',
        'systemd-hwdb-update.service',
        'systemd-modules-load.service',
        'systemd-vconsole-setup.service',
        'var-volatile.mount',
    ]
    
    for layer_num in range(1, layer_count + 1):
        layer_rootfs = d.getVar(f'OCI_LAYER_{layer_num}_ROOTFS')
        layer_name = d.getVar(f'OCI_LAYER_{layer_num}_NAME')
        
        if not layer_rootfs or not os.path.exists(layer_rootfs):
            continue
        
        bb.note(f"OCI: Post-processing layer {layer_num} '{layer_name}'")
        
        # Remove /etc/resolv.conf from ALL layers
        resolv_conf = os.path.join(layer_rootfs, 'etc/resolv.conf')
        if os.path.exists(resolv_conf) or os.path.islink(resolv_conf):
            os.remove(resolv_conf)
            bb.note(f"OCI: Removed /etc/resolv.conf from layer '{layer_name}'")
        
        resolv_systemd = os.path.join(layer_rootfs, 'etc/resolv-conf.systemd')
        if os.path.exists(resolv_systemd):
            os.remove(resolv_systemd)
        
        # Process base layer
        if layer_name == 'base':
            # Create /var/volatile directories
            volatile_tmp = os.path.join(layer_rootfs, 'var/volatile/tmp')
            volatile_log = os.path.join(layer_rootfs, 'var/volatile/log')
            bb.utils.mkdirhier(volatile_tmp)
            bb.utils.mkdirhier(volatile_log)
            os.chmod(volatile_tmp, 0o1777)
            os.chmod(volatile_log, 0o755)
            
            # Create container config files
            etc_containers = os.path.join(layer_rootfs, 'etc/containers')
            bb.utils.mkdirhier(etc_containers)
            
            with open(os.path.join(etc_containers, 'containers.conf'), 'w') as f:
                f.write('[engine]\ncgroup_manager = "cgroupfs"\nevents_logger = "file"\nruntime = "crun"\nnetns = "slirp4netns"\n\n[containers]\ncgroups = "disabled"\n')
            
            with open(os.path.join(etc_containers, 'storage.conf'), 'w') as f:
                f.write('[storage]\ndriver = "overlay"\nrunroot = "/run/containers/storage"\ngraphroot = "/var/lib/containers/storage"\n')
            
            with open(os.path.join(etc_containers, 'registries.conf'), 'w') as f:
                f.write('unqualified-search-registries = ["docker.io"]\n\n[[registry]]\nlocation = "docker.io"\n')
            
            with open(os.path.join(etc_containers, 'policy.json'), 'w') as f:
                f.write('{\n  "default": [\n    {\n      "type": "insecureAcceptAnything"\n    }\n  ]\n}\n')
            
            with open(os.path.join(layer_rootfs, 'etc/subuid'), 'w') as f:
                f.write('root:100000:65536\n')
            
            with open(os.path.join(layer_rootfs, 'etc/subgid'), 'w') as f:
                f.write('root:100000:65536\n')
            
            # Create entrypoint script
            entrypoint_script = os.path.join(layer_rootfs, 'entrypoint.sh')
            with open(entrypoint_script, 'w') as f:
                f.write('#!/bin/sh\nmkdir -p /lib64\nln -sf /lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 2>/dev/null || true\nfor f in /var/lib/greengrass/ggl.*.service; do\n    [ -f "$f" ] && ln -sf "$f" /etc/systemd/system/\ndone\nexec /sbin/init systemd.unified_cgroup_hierarchy=1\n')
            os.chmod(entrypoint_script, 0o755)
            
            # Create systemd directories
            systemd_system_dir = os.path.join(layer_rootfs, 'etc/systemd/system')
            bb.utils.mkdirhier(systemd_system_dir)
            
            # Mask systemd services
            for service in services_to_disable:
                service_link = os.path.join(systemd_system_dir, service)
                if not os.path.exists(service_link):
                    os.symlink('/dev/null', service_link)
            
            bb.note(f"OCI: Configured base layer")
}

# Run after oci_multilayer_install_packages
do_image_oci[prefuncs] += "oci_layer_postprocess"

IMAGE_CONTAINER_NO_DUMMY = "1"

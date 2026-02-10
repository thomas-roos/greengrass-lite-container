SUMMARY = "Greengrass Lite Single-Layer: SystemD + Greengrass v25"
DESCRIPTION = "Multi-layer OCI with systemd and greengrass-lite in separate layers"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

# Force rootfs and OCI layer rebuild when anything changes
do_rootfs[nostamp] = "1"
do_image_oci[nostamp] = "1"

# Increment this to force rebuild
PR = "r5"

# Enable multi-layer mode
OCI_LAYER_MODE = "single"

# Single layer with everything
# OCI_LAYERS = "\
#     systemd:packages:usrmerge-compat+base-files+base-passwd+netbase+systemd+systemd-serialgetty+libcgroup+ca-certificates \
#     greengrass:packages:greengrass-lite+podman+iptables+slirp4netns+python3-misc+python3-venv+python3-tomllib+python3-ensurepip+python3-pip+iputils-ping+crun \
# "

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
    import subprocess
    
    layer_mode = d.getVar('OCI_LAYER_MODE') or 'single'
    if layer_mode != 'multi':
        # Single layer mode - patch rootfs directly
        rootfs = d.getVar('IMAGE_ROOTFS')
        bb.note(f"OCI: Post-processing single-layer rootfs at {rootfs}")
        
        # Patch ggcore user to UID=0
        passwd_file = os.path.join(rootfs, 'etc/passwd')
        if os.path.exists(passwd_file):
            with open(passwd_file, 'r') as f:
                passwd_lines = f.readlines()
            with open(passwd_file, 'w') as f:
                for line in passwd_lines:
                    if line.startswith('ggcore:'):
                        f.write('ggcore:x:0:0:root:/root:/bin/sh\n')
                        bb.note(f"OCI: Patched ggcore to UID=0 in /etc/passwd")
                    else:
                        f.write(line)
        
        # Patch ggcore group to GID=0
        group_file = os.path.join(rootfs, 'etc/group')
        if os.path.exists(group_file):
            with open(group_file, 'r') as f:
                group_lines = f.readlines()
            with open(group_file, 'w') as f:
                for line in group_lines:
                    if line.startswith('ggcore:'):
                        f.write('ggcore:x:0:\n')
                        bb.note(f"OCI: Patched ggcore to GID=0 in /etc/group")
                    else:
                        f.write(line)
        
        # Create /home/ggcore/.config
        ggcore_home = os.path.join(rootfs, 'home/ggcore')
        ggcore_config = os.path.join(ggcore_home, '.config')
        bb.utils.mkdirhier(ggcore_config)
        os.chmod(ggcore_home, 0o755)
        os.chmod(ggcore_config, 0o755)
        bb.note(f"OCI: Created /home/ggcore/.config directory")
        
        # Remove /etc/resolv.conf
        resolv_conf = os.path.join(rootfs, 'etc/resolv.conf')
        if os.path.exists(resolv_conf) or os.path.islink(resolv_conf):
            os.remove(resolv_conf)
            bb.note(f"OCI: Removed /etc/resolv.conf")
        
        # Create /var/volatile directories
        volatile_tmp = os.path.join(rootfs, 'var/volatile/tmp')
        volatile_log = os.path.join(rootfs, 'var/volatile/log')
        bb.utils.mkdirhier(volatile_tmp)
        bb.utils.mkdirhier(volatile_log)
        os.chmod(volatile_tmp, 0o1777)
        os.chmod(volatile_log, 0o755)
        bb.note(f"OCI: Created /var/volatile directories")
        
        # Mask systemd services
        services_to_disable = [
            'systemd-udevd.service',
            'systemd-resolved.service',
            'systemd-hwdb-update.service',
            'systemd-modules-load.service',
            'systemd-vconsole-setup.service',
            'var-volatile.mount',
        ]
        systemd_system_dir = os.path.join(rootfs, 'etc/systemd/system')
        bb.utils.mkdirhier(systemd_system_dir)
        for service in services_to_disable:
            service_link = os.path.join(systemd_system_dir, service)
            if not os.path.exists(service_link):
                os.symlink('/dev/null', service_link)
                bb.note(f"OCI: Masked service {service}")
        
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
        
        # Only process systemd layer for other fixes
        if layer_name == 'systemd':
            # Add ggcore user with UID=0 and GID=0 to passwd
            passwd_file = os.path.join(layer_rootfs, 'etc/passwd')
            if os.path.exists(passwd_file):
                with open(passwd_file, 'r') as f:
                    passwd_lines = f.readlines()
                # Check if ggcore already exists
                if not any('ggcore:' in line for line in passwd_lines):
                    with open(passwd_file, 'a') as f:
                        f.write('ggcore:x:0:0:root:/root:/bin/sh\n')
                    bb.note(f"OCI: Added ggcore user with UID=0 to /etc/passwd")
            
            # Add ggcore group with GID=0 to group
            group_file = os.path.join(layer_rootfs, 'etc/group')
            if os.path.exists(group_file):
                with open(group_file, 'r') as f:
                    group_lines = f.readlines()
                # Check if ggcore already exists
                if not any('ggcore:' in line for line in group_lines):
                    with open(group_file, 'a') as f:
                        f.write('ggcore:x:0:\n')
                    bb.note(f"OCI: Added ggcore group with GID=0 to /etc/group")
            
            # Create /home/ggcore directory for ggcore user
            ggcore_home = os.path.join(layer_rootfs, 'home/ggcore')
            ggcore_config = os.path.join(ggcore_home, '.config')
            bb.utils.mkdirhier(ggcore_config)
            os.chmod(ggcore_home, 0o755)
            os.chmod(ggcore_config, 0o755)
            bb.note(f"OCI: Created /home/ggcore/.config directory in layer '{layer_name}'")
            
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
        # Process greengrass layer to fix ggcore UID
        if layer_name == 'greengrass':
            bb.note(f"OCI: Processing greengrass layer at {layer_rootfs}")
            
            # Create /home/ggcore directory for ggcore user
            ggcore_home = os.path.join(layer_rootfs, 'home/ggcore')
            ggcore_config = os.path.join(ggcore_home, '.config')
            bb.utils.mkdirhier(ggcore_config)
            os.chmod(ggcore_home, 0o755)
            os.chmod(ggcore_config, 0o755)
            bb.note(f"OCI: Created /home/ggcore/.config directory in layer '{layer_name}'")
            
            # Patch ggcore user to UID=0 in layer 2 (greengrass-lite package creates it with UID=999)
            passwd_file = os.path.join(layer_rootfs, 'etc/passwd')
            bb.note(f"OCI: Checking passwd file: {passwd_file}, exists={os.path.exists(passwd_file)}")
            if os.path.exists(passwd_file):
                with open(passwd_file, 'r') as f:
                    passwd_lines = f.readlines()
                bb.note(f"OCI: Found {len(passwd_lines)} lines in passwd")
                # Replace ggcore line with UID=0 version
                patched = False
                with open(passwd_file, 'w') as f:
                    for line in passwd_lines:
                        if line.startswith('ggcore:'):
                            bb.note(f"OCI: Found ggcore line: {line.strip()}")
                            f.write('ggcore:x:0:0:root:/root:/bin/sh\n')
                            bb.note(f"OCI: Patched ggcore to UID=0 in /etc/passwd")
                            patched = True
                        else:
                            f.write(line)
                if not patched:
                    bb.note(f"OCI: WARNING - No ggcore line found in passwd!")
            else:
                bb.note(f"OCI: WARNING - passwd file does not exist!")
            
            # Patch ggcore group to GID=0 in layer 2
            group_file = os.path.join(layer_rootfs, 'etc/group')
            if os.path.exists(group_file):
                with open(group_file, 'r') as f:
                    group_lines = f.readlines()
                # Replace ggcore line with GID=0 version
                with open(group_file, 'w') as f:
                    for line in group_lines:
                        if line.startswith('ggcore:'):
                            f.write('ggcore:x:0:\n')
                            bb.note(f"OCI: Patched ggcore to GID=0 in /etc/group")
                        else:
                            f.write(line)
                bb.note(f"OCI: Patched ggcore to GID=0 in /etc/group")
}

# Run after oci_multilayer_install_packages
do_image_oci[prefuncs] += "oci_layer_postprocess"

IMAGE_CONTAINER_NO_DUMMY = "1"

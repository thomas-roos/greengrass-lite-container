SUMMARY = "Push Greengrass Lite multi-arch image to GitHub Container Registry"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit container-registry

# GitHub Container Registry configuration
CONTAINER_REGISTRY_URL = "ghcr.io"
CONTAINER_REGISTRY_NAMESPACE = "thomas-roos"
CONTAINER_REGISTRY_TLS_VERIFY = "true"
CONTAINER_REGISTRY_TAG_STRATEGY = "latest git"

# Depend on the multiarch image and skopeo
DEPENDS = "greengrass-lite-multiarch skopeo-native"

do_unpack[noexec] = "1"
do_patch[noexec] = "1"
do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"

python do_push_to_registry() {
    import os
    
    oci_path = os.path.join(
        d.getVar('DEPLOY_DIR_IMAGE'),
        'greengrass-lite-multiarch-multiarch-oci'
    )
    
    if not os.path.exists(oci_path):
        bb.fatal(f"Multi-arch OCI not found: {oci_path}")
    
    bb.note(f"Pushing multi-arch image from: {oci_path}")
    
    refs = container_registry_push(d, oci_path, 'greengrass-lite')
    
    bb.note("=" * 60)
    bb.note(f"Pushed {len(refs)} tags:")
    for ref in refs:
        bb.note(f"  {ref}")
    bb.note("=" * 60)
}

addtask push_to_registry after do_prepare_recipe_sysroot before do_build

do_push_to_registry[network] = "1"
do_push_to_registry[nostamp] = "1"

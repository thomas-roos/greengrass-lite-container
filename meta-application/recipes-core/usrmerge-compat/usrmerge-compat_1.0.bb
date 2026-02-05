SUMMARY = "usrmerge compatibility symlinks for OCI containers"
DESCRIPTION = "Provides /bin, /sbin, /lib symlinks for usrmerge compatibility"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

ALLOW_EMPTY:${PN} = "1"

do_install() {
    # Create symlinks at root for usrmerge compatibility
    ln -sf usr/bin ${D}/bin
    ln -sf usr/sbin ${D}/sbin
    ln -sf usr/lib ${D}/lib
    if [ "${baselib}" != "lib" ]; then
        ln -sf usr/${baselib} ${D}/${baselib}
    fi
}

FILES:${PN} = "/bin /sbin /lib ${@'/lib64' if d.getVar('baselib') != 'lib' else ''}"

# This package must be installed first
RPROVIDES:${PN} = "usrmerge-compat"

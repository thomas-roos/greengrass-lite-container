# Create /lib64 symlink for x86_64 compatibility
do_install:append() {
    install -d ${D}/lib64
    ln -sf /lib/ld-linux-x86-64.so.2 ${D}/lib64/ld-linux-x86-64.so.2
}

FILES:${PN} += "/lib64"

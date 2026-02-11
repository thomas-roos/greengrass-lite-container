#!/bin/sh
mkdir -p /lib64
ln -sf /lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 2>/dev/null || true
for f in /var/lib/greengrass/ggl.*.service; do
    [ -f "$f" ] && ln -sf "$f" /etc/systemd/system/
done
exec /sbin/init systemd.unified_cgroup_hierarchy=1

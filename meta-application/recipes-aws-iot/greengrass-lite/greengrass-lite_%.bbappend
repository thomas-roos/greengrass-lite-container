# Run ggcore as root user (UID=0, GID=0) for container environment
# Create /home/ggcore directory
USERADD_PARAM:${PN} = "-r -m -d /home/${gg_user} -N -u 0 -g 0 -o -s /bin/false ${gg_user}; -r -M -N -g ${ggc_group} -s /bin/false ${ggc_user}"
GROUPADD_PARAM:${PN} = "-r ${gg_group}; -r ${ggc_group}"

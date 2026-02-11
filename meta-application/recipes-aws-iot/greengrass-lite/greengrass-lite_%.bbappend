# Override ggcore to use root group (GID=0) instead of creating new group
# This allows ggcore to have root privileges without UID=0
USERADD_PARAM:${PN} = "-r -M -N -g root -s /bin/false ${gg_user}; -r -M -N -g ${ggc_group} -s /bin/false ${ggc_user}"
GROUPADD_PARAM:${PN} = "-r ${ggc_group}"

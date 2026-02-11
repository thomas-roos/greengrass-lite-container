# Make ggcore user part of root group (GID=0) instead of creating ggcore group
USERADD_PARAM:${PN} = "-r -M -N -g root -s /bin/false ${gg_user}; -r -M -N -g ${ggc_group} -s /bin/false ${ggc_user}"
GROUPADD_PARAM:${PN} = "-r ${ggc_group}"

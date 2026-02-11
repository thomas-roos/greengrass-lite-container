# Keep ggcore group creation, but make ggcore user part of root group (GID=0)
USERADD_PARAM:${PN} = "-r -M -N -g root -s /bin/false ${gg_user}; -r -M -N -g ${ggc_group} -s /bin/false ${ggc_user}"

# Make ggcore user part of root group (GID=0)
# Keep ggcore group for file ownership
USERADD_PARAM:${PN} = "-r -M -N -g root -s /bin/false ${gg_user}; -r -M -N -g ${ggc_group} -s /bin/false ${ggc_user}"
GROUPADD_PARAM:${PN} = "-r ${gg_group}; -r ${ggc_group}"

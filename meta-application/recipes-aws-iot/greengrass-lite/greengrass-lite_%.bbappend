# Override ggcore user to use UID=0 (root)
USERADD_PARAM:${PN} = "-r -M -N -u 0 -g root -s /bin/false ${gg_user}; -r -M -N -g ${ggc_group} -s /bin/false ${ggc_user}"
GROUPADD_PARAM:${PN} = "-r ${ggc_group}"

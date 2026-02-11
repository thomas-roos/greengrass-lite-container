# Prevent greengrass-lite from creating users
# ggcore is already created in base-passwd with UID=0

# Provide dummy values to satisfy useradd class requirement
GROUPADD_PARAM:${PN} = "-r dummygroup"
USERADD_PARAM:${PN} = "-r -M -N -g dummygroup -s /bin/false dummyuser"

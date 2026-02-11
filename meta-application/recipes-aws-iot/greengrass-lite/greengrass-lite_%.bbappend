# Prevent greengrass-lite from creating users
# ggcore is already created in base-passwd with UID=0

# Clear user/group creation
GROUPADD_PARAM:${PN} = ""
USERADD_PARAM:${PN} = ""

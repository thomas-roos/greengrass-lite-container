FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Keep default ggcore user in config, but ggcore will have UID=0 in the image
# This allows the config to use ggcore:ggcore while actually running as root

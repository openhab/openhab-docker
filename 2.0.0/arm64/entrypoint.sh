#!/bin/bash -x
set -euo pipefail
IFS=$'\n\t'

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 10
# GPIO Group for RPI access
NEW_USER_ID=${USER_ID:-9001}
echo "Starting with openhab user id: $NEW_USER_ID"
if ! id openhab >/dev/null 2>&1; then
  echo "Create user openhab with id 9001"
  adduser -u $NEW_USER_ID --disabled-password --gecos '' --home ${APPDIR} openhab &&\
    groupadd -g 14 uucp2 &&\
    groupadd -g 16 dialout2 &&\
    groupadd -g 18 dialout3 &&\
    groupadd -g 32 uucp3 &&\
    groupadd -g 997 gpio &&\
    adduser openhab dialout &&\
    adduser openhab uucp &&\
    adduser openhab uucp2 &&\
    adduser openhab dialout2 &&\
    adduser openhab dialout3 &&\
    adduser openhab uucp3 &&\
    adduser openhab gpio
fi

# Initialize empty host volumes
if [ -z "$(ls -A "${APPDIR}/userdata")" ]; then
  # Copy userdata dir
  echo "No userdata found... initializing."
  cp -av "${APPDIR}/userdata.dist/." "${APPDIR}/userdata/"
fi

if [ -z "$(ls -A "${APPDIR}/conf")" ]; then
  # Copy userdata dir
  echo "No configuration found... initializing."
  cp -av "${APPDIR}/conf.dist/." "${APPDIR}/conf/"
fi

# Set openhab folder permission
chown -R openhab:openhab ${APPDIR}

# Prettier interface
if [ "$1" = 'server' ] || [ "$1" = 'openhab' ]; then
  gosu openhab "${APPDIR}/start.sh"
elif [ "$1" = 'debug' ]; then
  gosu openhab "${APPDIR}/start_debug.sh"
else
  gosu openhab "$@"
fi


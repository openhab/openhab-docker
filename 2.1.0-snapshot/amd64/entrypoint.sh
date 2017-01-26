#!/bin/bash -x
set -euo pipefail
IFS=$'\n\t'

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback to an high uid to avoid collision with user from host.

USER_ID=${LOCAL_USER_ID:-9001}

echo "Starting with UID : $USER_ID"

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 10
# GPIO Group for RPI access
adduser -u $USER_ID --disabled-password --gecos '' --home ${APPDIR} openhab &&\
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

# Prettier interface
if [ "$1" = 'server' ] || [ "$1" = 'openhab' ]; then
  gosu openhab "${APPDIR}/start.sh"
elif [ "$1" = 'debug' ]; then
  gosu openhab "${APPDIR}/start_debug.sh"
elif [ "$1" = 'console' ] || [ "$1" = 'shell' ]; then
  gosu openhab "${APPDIR}/runtime/bin/client"
else
  gosu openhab "$@"
fi


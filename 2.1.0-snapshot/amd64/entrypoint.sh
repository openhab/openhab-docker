#!/bin/bash -x
set -euo pipefail
IFS=$'\n\t'

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 10
# GPIO Group for RPI access
NEW_USER_ID=${USER_ID:-9001}
echo "Starting with openhab user id: $NEW_USER_ID"
if ! id -u openhab >/dev/null 2>&1; then
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

# Copy initial files to host volume
case ${OPENHAB_VERSION} in
  1.8.3)
      if [ -z "$(ls -A "${APPDIR}/configurations")" ]; then
        # Copy userdata dir for version 1.8.3
        echo "No configuration found... initializing."
        cp -av "${APPDIR}/configurations.dist/." "${APPDIR}/configurations/"
      fi
    ;;
  2.0.0|2.1.0-snapshot)
      # Initialize empty host volumes
      if [ -z "$(ls -A "${APPDIR}/userdata")" ]; then
        # Copy userdata dir for version 2.0.0
        echo "No userdata found... initializing."
        cp -av "${APPDIR}/userdata.dist/." "${APPDIR}/userdata/"
      fi

      if [ -z "$(ls -A "${APPDIR}/conf")" ]; then
        # Copy userdata dir for version 2.0.0
        echo "No configuration found... initializing."
        cp -av "${APPDIR}/conf.dist/." "${APPDIR}/conf/"
      fi
    ;;
  *)
      echo openHAB version ${OPENHAB_VERSION} not supported!
    ;;
esac

# Set openhab folder permission
chown -R openhab:openhab ${APPDIR}

exec "$@"


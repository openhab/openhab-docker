#!/bin/bash -x

# Karaf needs a pseudo-TTY so exit and instruct user to allocate one when necessary
test -t 0
if [ $? -eq 1 ]; then
    echo "Please start the openHAB container with a pseudo-TTY using the -t option or 'tty: true' with docker compose"
    exit 1
fi

set -euo pipefail
IFS=$'\n\t'

# Deleting instance.properties to avoid karaf PID conflict on restart
# See: https://github.com/openhab/openhab-docker/issues/99
rm -f /openhab/runtime/instances/instance.properties

# The instance.properties file in OH2.x is installed in the tmp
# directory
rm -f /openhab/userdata/tmp/instances/instance.properties

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 10
# GPIO Group for RPI access
NEW_USER_ID=${USER_ID:-9001}
NEW_GROUP_ID=${GROUP_ID:-$NEW_USER_ID}
echo "Starting with openhab user id: $NEW_USER_ID and group id: $NEW_GROUP_ID"
if ! id -u openhab >/dev/null 2>&1; then
  echo "Create group openhab with id ${NEW_GROUP_ID}"
  groupadd -g $NEW_GROUP_ID openhab
  echo "Create user openhab with id ${NEW_USER_ID}"
  adduser -u $NEW_USER_ID --disabled-password --gecos '' --home ${APPDIR} --gid $NEW_GROUP_ID openhab
  groupadd -g 14 uucp2
  groupadd -g 16 dialout2
  groupadd -g 18 dialout3
  groupadd -g 32 uucp3
  groupadd -g 997 gpio
  adduser openhab dialout
  adduser openhab uucp
  adduser openhab uucp2
  adduser openhab dialout2
  adduser openhab dialout3
  adduser openhab uucp3
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
  2.0.0|2.1.0|2.2.0|2.3.0-snapshot)
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

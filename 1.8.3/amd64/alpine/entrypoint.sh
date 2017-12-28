#!/bin/sh -x

# Karaf needs a pseudo-TTY so exit and instruct user to allocate one when necessary
test -t 0
if [ $? -eq 1 ]; then
    echo "Please start the openHAB container with a pseudo-TTY using the -t option or 'tty: true' with docker compose"
    exit 1
fi

set -euo pipefail
IFS=$'\n\t'

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 10
# GPIO Group for RPI access
NEW_USER_ID=${USER_ID:-9001}
echo "Starting with openhab user id: $NEW_USER_ID"
if ! id -u openhab >/dev/null 2>&1; then
  echo "Create user openhab with id 9001"
  adduser -u $NEW_USER_ID -D -g '' -h ${APPDIR} openhab
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

      # Upgrade userdata if versions do not match
      curVersion=$(< ${APPDIR}/userdata/etc/version.properties grep build-no | cut -d : -f 2 | tr -d '[:space]')
      imgVersion=$(< ${APPDIR}/userdata.dist/etc/version.properties grep build-no | cut -d : -f 2 | tr -d '[:space]')
      echo "Current \"${curVersion}\" Image \"${imgVersion}\"" # TODO remove
      if [ "${curVersion}" != "${imgVersion}" ]; then
        echo "Image version \"${imgVersion}\" is different from userdata version \"${curVersion}\""

        # Make a backup of userdata
	backupFile=userdata-$(date +"%FT%H:%M:%S").tar
        tar cf /tmp/${backupFile} ${APPDIR}/userdata
        if [ ! -d "${APPDIR}/userdata/backup" ]; then
          mkdir ${APPDIR}/userdata/backup
        fi
        cp /tmp/${backupFile} ${APPDIR}/userdata/backup/
        echo "You can find backup of userdata in ${APPDIR}/userdata/backup/${backupFile}"

        # Copy over the updated files
        cp ${APPDIR}/userdata.dist/etc/all.policy ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/branding.properties ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/branding-ssh.properties ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/config.properties ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/custom.properties ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/version.properties ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/distribution.info ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/jre.properties ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/profile.cfg ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/startup.properties ${APPDIR}/userdata/etc
        cp ${APPDIR}/userdata.dist/etc/org.apache.karaf* ${APPDIR}/userdata/etc/
        cp ${APPDIR}/userdata.dist/etc/org.ops4j.pax.url.mvn.cfg ${APPDIR}/userdata/etc/
        echo "Replaced files in userdata/etc with newer versions"

        # Clear the cache and tmp
        rm -rf ${APPDIR}/userdata/cache/*
        rm -rf ${APPDIR}/userdata/tmp/*
        echo "Cleared the cache and tmp"

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

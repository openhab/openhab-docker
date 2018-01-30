#!/bin/bash -x

# Karaf needs a pseudo-TTY so exit and instruct user to allocate one when necessary
test -t 0
if [ $? -eq 1 ]; then
    echo "Please start the openHAB container with a pseudo-TTY using the -t option or 'tty: true' with docker compose"
    exit 1
fi

set -euo pipefail
IFS=$'\n\t'

# Install Java unlimited strength cryptography
if [ "${CRYPTO_POLICY}" = "unlimited" ] && [ ! -f "${JAVA_HOME}/jre/lib/security/README.txt" ]; then
  echo "Installing Zulu Cryptography Extension Kit (\"CEK\")..."
  wget -q -O /tmp/ZuluJCEPolicies.zip https://cdn.azul.com/zcek/bin/ZuluJCEPolicies.zip
  unzip -jo -d ${JAVA_HOME}/jre/lib/security /tmp/ZuluJCEPolicies.zip
  rm /tmp/ZuluJCEPolicies.zip
fi

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

      # Upgrade userdata if versions do not match
      if [ ! -z $(cmp "${APPDIR}/userdata/etc/version.properties" "${APPDIR}/userdata.dist/etc/version.properties") ]; then
        echo "Image and userdata versions differ! Starting an upgrade."

        # Make a backup of userdata
        backupFile=userdata-$(date +"%FT%H:%M:%S").tar
        if [ ! -d "${APPDIR}/userdata/backup" ]; then
          mkdir "${APPDIR}/userdata/backup"
        fi
        tar --exclude="${APPDIR}/userdata/backup" -c -f "${APPDIR}/userdata/backup/${backupFile}" "${APPDIR}/userdata"
        echo "You can find backup of userdata in ${APPDIR}/userdata/backup/${backupFile}"

        # Copy over the updated files
        cp "${APPDIR}/userdata.dist/etc/all.policy" "${APPDIR}/userdata/etc/"
        cp "${APPDIR}/userdata.dist/etc/branding.properties" "${APPDIR}/userdata/etc/"
        cp "${APPDIR}/userdata.dist/etc/branding-ssh.properties" "${APPDIR}/userdata/etc/"
        cp "${APPDIR}/userdata.dist/etc/config.properties" "${APPDIR}/userdata/etc/"
        cp "${APPDIR}/userdata.dist/etc/custom.properties" "${APPDIR}/userdata/etc/"
        if [ -f "${APPDIR}/userdata.dist/etc/custom.system.properties" ]; then
          cp "${APPDIR}/userdata.dist/etc/custom.system.properties" "${APPDIR}/userdata/etc/"
        fi
        cp "${APPDIR}/userdata.dist/etc/distribution.info" "${APPDIR}/userdata/etc/"
        cp "${APPDIR}/userdata.dist/etc/jre.properties" "${APPDIR}/userdata/etc/"
        cp "${APPDIR}/userdata.dist/etc/org.apache.karaf"* "${APPDIR}/userdata/etc/"
        cp "${APPDIR}/userdata.dist/etc/org.ops4j.pax.url.mvn.cfg" "${APPDIR}/userdata/etc/"
        if [ -f "${APPDIR}/userdata.dist/etc/overrides.properties" ]; then
          cp "${APPDIR}/userdata.dist/etc/overrides.properties" "${APPDIR}/userdata/etc/"
        fi
        cp "${APPDIR}/userdata.dist/etc/profile.cfg" "${APPDIR}/userdata/etc/"
        cp "${APPDIR}/userdata.dist/etc/startup.properties" "${APPDIR}/userdata/etc"
        cp "${APPDIR}/userdata.dist/etc/system.properties" "${APPDIR}/userdata/etc"
        cp "${APPDIR}/userdata.dist/etc/version.properties" "${APPDIR}/userdata/etc/"
        echo "Replaced files in userdata/etc with newer versions"

        # Clear the cache and tmp
        rm -rf "${APPDIR}/userdata/cache"
        rm -rf "${APPDIR}/userdata/tmp"
        mkdir "${APPDIR}/userdata/cache"
        mkdir "${APPDIR}/userdata/tmp"
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

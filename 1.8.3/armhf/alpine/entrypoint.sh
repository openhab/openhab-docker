#!/bin/bash -x

interactive=$(if test -t 0; then echo true; else echo false; fi)
set -euo pipefail
IFS=$'\n\t'

# Install Java unlimited strength cryptography
if [ "${CRYPTO_POLICY}" = "unlimited" ] && [ ! -d "${JAVA_HOME}/jre/lib/security/policy/unlimited" ]; then
  echo "Installing OpenJDK unlimited strength cryptography policy..."
  mkdir "${JAVA_HOME}/jre/lib/security/policy/unlimited"
  apk fix --no-cache openjdk8-jre-lib
fi

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 14
# GPIO Group for RPI access
NEW_USER_ID=${USER_ID:-9001}
NEW_GROUP_ID=${GROUP_ID:-$NEW_USER_ID}
echo "Starting with openhab user id: $NEW_USER_ID and group id: $NEW_GROUP_ID"
if ! id -u openhab >/dev/null 2>&1; then
  echo "Create group openhab with id ${NEW_GROUP_ID}"
  addgroup -g $NEW_GROUP_ID openhab
  echo "Create user openhab with id ${NEW_USER_ID}"
  adduser -u $NEW_USER_ID -D -g '' -h ${APPDIR} -G openhab openhab
  adduser openhab dialout
  adduser openhab uucp
fi

# Copy initial files to host volume
case ${OPENHAB_VERSION} in
  1.*)
      if [ -z "$(ls -A "${APPDIR}/configurations")" ]; then
        # Copy userdata dir for openHAB 1.x
        echo "No configuration found... initializing."
        cp -av "${APPDIR}/configurations.dist/." "${APPDIR}/configurations/"
      fi
    ;;
  2.*)
      # Initialize empty host volumes
      if [ -z "$(ls -A "${APPDIR}/userdata")" ]; then
        # Copy userdata dir for openHAB 2.x
        echo "No userdata found... initializing."
        cp -av "${APPDIR}/userdata.dist/." "${APPDIR}/userdata/"
      fi

      # Upgrade userdata if versions do not match
      if [ ! -z $(cmp "${APPDIR}/userdata/etc/version.properties" "${APPDIR}/userdata.dist/etc/version.properties") ]; then
        echo "Image and userdata versions differ! Starting an upgrade."

        # Make a backup of userdata
        backupFile=userdata-$(date +"%FT%H-%M-%S").tar
        if [ ! -d "${APPDIR}/userdata/backup" ]; then
          mkdir "${APPDIR}/userdata/backup"
        fi
        tar -c -f "${APPDIR}/userdata/backup/${backupFile}" --exclude "backup/*" "${APPDIR}/userdata"
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

        # Remove necessary files after installation
        rm -rf "${APPDIR}/userdata/etc/org.openhab.addons.cfg"
        if [ ! -f "${APPDIR}/userdata.dist/etc/overrides.properties" ]; then
          rm -rf "${APPDIR}/userdata/etc/overrides.properties"
        fi

        # Clear the cache and tmp
        rm -rf "${APPDIR}/userdata/cache"
        rm -rf "${APPDIR}/userdata/tmp"
        mkdir "${APPDIR}/userdata/cache"
        mkdir "${APPDIR}/userdata/tmp"
        echo "Cleared the cache and tmp"
      fi

      if [ -z "$(ls -A "${APPDIR}/conf")" ]; then
        # Copy userdata dir for openHAB 2.x
        echo "No configuration found... initializing."
        cp -av "${APPDIR}/conf.dist/." "${APPDIR}/conf/"
      fi
    ;;
  *)
      echo openHAB version ${OPENHAB_VERSION} not supported!
    ;;
esac

# Run s6-style init continuation scripts if existent
if [ -d /etc/cont-init.d ]
then
    for script in $(find /etc/cont-init.d -type f | grep -v \~ | sort)
    do
        . ${script}
    done
fi

# Set openhab folder permission
chown -R openhab:openhab ${APPDIR}
sync

# Use server mode with the default command when there is no pseudo-TTY
if [ "$interactive" == "false" ] && [ "$(IFS=" "; echo "$@")" == "su-exec openhab ./start.sh" ]; then
    command=($@ server)
    exec "${command[@]}"
else
    exec "$@"
fi

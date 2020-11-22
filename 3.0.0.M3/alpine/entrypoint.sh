#!/bin/bash -x

interactive=$(if test -t 0; then echo true; else echo false; fi)
set -euo pipefail
IFS=$'\n\t'

# Configure Java unlimited strength cryptography
if [ "${CRYPTO_POLICY}" = "unlimited" ]; then
  echo "Configuring OpenJDK ${JAVA_VERSION} unlimited strength cryptography policy..."
  if [ "${JAVA_VERSION}" = "8" ]; then
    java_security_file="${JAVA_HOME}/jre/lib/security/java.security"
  elif [ "${JAVA_VERSION}" = "11" ]; then
    java_security_file="${JAVA_HOME}/conf/security/java.security"
  fi
  sed -i 's/^crypto.policy=limited/crypto.policy=unlimited/' "${java_security_file}"
fi

# Deleting instance.properties to avoid karaf PID conflict on restart
# See: https://github.com/openhab/openhab-docker/issues/99
rm -f "${OPENHAB_HOME}/runtime/instances/instance.properties"

# The instance.properties file in openHAB 2.x/3.x is installed in the tmp
# directory
rm -f "${OPENHAB_USERDATA}/tmp/instances/instance.properties"

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 14
# GPIO Group for RPI access
NEW_USER_ID=${USER_ID:-9001}
NEW_GROUP_ID=${GROUP_ID:-$NEW_USER_ID}
echo "Starting with openhab user id: $NEW_USER_ID and group id: $NEW_GROUP_ID"
if ! id -u openhab >/dev/null 2>&1; then
  if [ -z "$(getent group $NEW_GROUP_ID)" ]; then
    echo "Create group openhab with id ${NEW_GROUP_ID}"
    groupadd -g $NEW_GROUP_ID openhab
  else
    group_name=$(getent group $NEW_GROUP_ID | cut -d: -f1)
    echo "Rename group $group_name to openhab"
    groupmod --new-name openhab $group_name
  fi
  echo "Create user openhab with id ${NEW_USER_ID}"
  adduser -u $NEW_USER_ID -D -g '' -h ${OPENHAB_HOME} -G openhab openhab
  adduser openhab dialout
  adduser openhab uucp
fi


initialize_volume() {
  volume="$1"
  source="$2"

  if [ -z "$(ls -A "$volume")" ]; then
    echo "Initializing empty volume ${volume} ..."
    cp -av "${source}/." "${volume}/"
  fi
}

# Initialize empty volumes and update userdata
initialize_volume "${OPENHAB_CONF}" "${OPENHAB_HOME}/dist/conf"
initialize_volume "${OPENHAB_USERDATA}" "${OPENHAB_HOME}/dist/userdata"

# Update userdata if versions do not match
if [ ! -z $(cmp "${OPENHAB_USERDATA}/etc/version.properties" "${OPENHAB_HOME}/dist/userdata/etc/version.properties") ]; then
  echo "Image and userdata versions differ! Starting an upgrade." | tee "${OPENHAB_LOGDIR}/update.log"

  # Make a backup of userdata
  backup_file=userdata-$(date +"%FT%H-%M-%S").tar
  if [ ! -d "${OPENHAB_BACKUPS}" ]; then
    mkdir "${OPENHAB_BACKUPS}"
  fi
  tar -c -f "${OPENHAB_BACKUPS}/${backup_file}" --exclude "backup/*" "${OPENHAB_USERDATA}"
  echo "You can find backup of userdata in ${OPENHAB_BACKUPS}/${backup_file}" | tee -a "${OPENHAB_LOGDIR}/update.log"

  exec "${OPENHAB_HOME}/runtime/bin/update" 2>&1 | tee -a "${OPENHAB_LOGDIR}/update.log"
fi

# Set openhab folder permission
chown -R openhab:openhab "${OPENHAB_HOME}"
sync

# Run s6-style init continuation scripts if existent
if [ -d /etc/cont-init.d ]
then
    for script in $(find /etc/cont-init.d -type f | grep -v \~ | sort)
    do
        . "${script}"
    done
fi

# sync again after continuation scripts have been run
sync

# Use server mode with the default command when there is no pseudo-TTY
if [ "$interactive" == "false" ] && [ "$(IFS=" "; echo "$@")" == "su-exec openhab tini -s ./start.sh" ]; then
    command=($@ server)
    exec "${command[@]}"
else
    exec "$@"
fi

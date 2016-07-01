#!/bin/bash -x
set -euo pipefail
IFS=$'\n\t'

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
  gosu openhab "${APPDIR}/runtime/karaf/bin/client"
else
  gosu openhab "$@"
fi


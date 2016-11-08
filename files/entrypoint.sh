#!/bin/bash -x
set -euo pipefail
IFS=$'\n\t'

# Initialize empty host volumes
if [ -z "$(ls -A "${APPDIR}/userdata")" ]; then
  # Copy userdata dir
  echo "No userdata found... initializing."
  sudo cp -av "${APPDIR}/userdata.dist/." "${APPDIR}/userdata/"
fi

if [ -z "$(ls -A "${APPDIR}/conf")" ]; then
  # Copy userdata dir
  echo "No configuration found... initializing."
  sudo cp -av "${APPDIR}/conf.dist/." "${APPDIR}/conf/"
fi

# Prettier interface
if [ "$1" = 'server' ] || [ "$1" = 'openhab' ]; then
  eval "${APPDIR}/start.sh"
elif [ "$1" = 'debug' ]; then
  eval "${APPDIR}/start_debug.sh"
elif [ "$1" = 'console' ] || [ "$1" = 'shell' ]; then
  exec "${APPDIR}/runtime/bin/client"
else
  exec "$@"
fi


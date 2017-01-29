#!/bin/bash -x
set -euo pipefail
IFS=$'\n\t'

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


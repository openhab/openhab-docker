#!/bin/bash
set -eo pipefail

./update-docker-files.sh
./update-travis-config.sh
./update-readme.sh

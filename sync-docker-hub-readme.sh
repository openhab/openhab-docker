#!/bin/bash
set -eo pipefail

# This script is based on the GitHub Docker Hub Description action.
# See: https://github.com/peter-evans/dockerhub-description/blob/master/entrypoint.sh

# Acquire token for Docker Hub API
LOGIN_PAYLOAD="{\"username\": \"${DOCKER_USERNAME}\", \"password\": \"${DOCKER_PASSWORD}\"}"
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d "${LOGIN_PAYLOAD}" https://hub.docker.com/v2/users/login/ | jq -r .token)

# Send a PATCH request to update the description of the repository
echo "Updating README for $DOCKER_REPO on Docker Hub"
README_FILEPATH="./README.md"
REPO_URL="https://hub.docker.com/v2/repositories/${DOCKER_REPO}/"
RESPONSE_CODE=$(curl -s --write-out %{response_code} --output /dev/null -H "Authorization: JWT ${TOKEN}" -X PATCH --data-urlencode full_description@${README_FILEPATH} ${REPO_URL})

if [ $RESPONSE_CODE -eq 200 ]; then
    echo "Successfully updated README for $DOCKER_REPO on Docker Hub"
    exit 0
else
    echo "Failed to update README for $DOCKER_REPO on Docker Hub (Response code: $RESPONSE_CODE)"
    exit 1
fi

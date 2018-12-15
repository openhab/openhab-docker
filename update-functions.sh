#!/bin/bash
set -eo pipefail

# Supported architectures
arches() {
	echo "amd64 arm64 armhf"
}

# Supported base images
bases() {
	echo "alpine debian"
}

docker_repo() {
	echo "${DOCKER_REPO:=openhab/openhab}"
}

last_stable_version() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' versions | sort --unique --version-sort | tail -n 1
}

next_stable_version() {
	a=($(echo "$(last_stable_version)" | tr '.' '\n'))
	echo "${a[0]}.$((a[1]+1)).${a[2]}"
}

stable_versions() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' versions | sort --unique --version-sort
}

milestone_versions() {
	grep -E "$(next_stable_version)\.(M|RC)[0-9]+$" versions | sort --unique --version-sort | tail -n 3 || echo ""
}

last_milestone_version() {
	grep -E "$(next_stable_version)\.(M|RC)[0-9]+$" versions | sort --unique --version-sort | tail -n 1 || echo ""
}

snapshot_version() {
	echo "$(next_stable_version)-snapshot"
}

build_versions() {
	echo "$(stable_versions) $(milestone_versions) $(snapshot_version)"
}

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

next_stable_version_major_update() {
	# (un)comment false/return based on if the next stable version is a major update
	#false
	return
}

next_stable_version() {
	a=($(last_stable_version | tr '.' '\n'))
	if next_stable_version_major_update; then
		echo  "$((a[0]+1)).0.0"
	else
		echo "${a[0]}.$((a[1]+1)).${a[2]}"
	fi
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

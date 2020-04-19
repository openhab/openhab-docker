#!/bin/bash
set -eo pipefail

# Supported architectures
arches() {
	version="$1"
	base="$2"

	if [[ "$version" =~ ^3.*$ ]] && [ "$base" == "alpine" ]; then
		# There is no armhf Alpine image for openHAB 3 because the openjdk11 package is unavailable for this architecture
		echo "amd64 arm64"
	else
		echo "amd64 armhf arm64"
	fi
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

stable_versions() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' versions | sort --unique --version-sort
}

snapshot_versions() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+-snapshot$' versions | sort --unique --version-sort || echo ""
}

last_snapshot_version() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+-snapshot$' versions | sort --unique --version-sort | tail -n 1 || echo ""
}

next_stable_version() {
	sed 's/-snapshot//' <<< last_snapshot_version
}

milestone_versions() {
	grep -E "$(next_stable_version)\.(M|RC)[0-9]+$" versions | sort --unique --version-sort | tail -n 3 || echo ""
}

last_milestone_version() {
	grep -E "$(next_stable_version)\.(M|RC)[0-9]+$" versions | sort --unique --version-sort | tail -n 1 || echo ""
}

build_versions() {
	echo "$(stable_versions) $(milestone_versions) $(snapshot_versions)"
}

validate_readme_constraints() {
	count=$(wc -m <README.md)
	if [[ $count -ge 25000 ]]; then
		echo "README.md contains $count characters which exceeds the 25000 character limit of Docker Hub"
		exit 1;
	fi
}

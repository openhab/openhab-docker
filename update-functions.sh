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

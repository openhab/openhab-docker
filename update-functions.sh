#!/bin/bash
set -eo pipefail

# Supported base images
bases() {
	echo "alpine debian"
}

docker_repo() {
	echo "${DOCKER_REPO:=openhab/openhab}"
}

# Supported Docker platforms
platforms() {
	version="$1"
	base="$2"

	if [[ "$version" =~ ^3.*$ ]] && [ "$base" == "alpine" ]; then
		# There is no linux/arm/v7 Alpine image for openHAB 3 because the openjdk11 package is unavailable for this architecture
		echo "linux/amd64,linux/arm64"
	else
		echo "linux/amd64,linux/arm64,linux/arm/v7"
	fi
}

tags() {
	version="$1"
	base="$2"

	tags=()

	if [ "$base" == "debian" ]; then
		tags+=("$(docker_repo):$version")
	fi

	tags+=("$(docker_repo):$version-$base")

	if [ "$version" == "$(last_stable_version)" ]; then
		if [ "$base" == "debian" ]; then
			tags+=("$(docker_repo):latest")
		fi
		tags+=("$(docker_repo):latest-$base")
	fi

	milestone_maturity_version="$(last_milestone_version)"
	if [ "$milestone_maturity_version" == "" ]; then
		milestone_maturity_version="$(last_stable_version)"
	fi

	if [ "$version" == "$milestone_maturity_version" ]; then
		if [ "$base" == "debian" ]; then
			tags+=("$(docker_repo):milestone")
		fi
		tags+=("$(docker_repo):milestone-$base")
	fi

	if [ "$version" == "$(last_snapshot_version)" ]; then
		if [ "$base" == "debian" ]; then
			tags+=("$(docker_repo):snapshot")
		fi
		tags+=("$(docker_repo):snapshot-$base")
	fi

	echo $(IFS=' '; echo "${tags[*]}")
}

last_stable_version() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' versions | sort --unique --version-sort | tail -n 1
}

stable_versions() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' versions | sort --unique --version-sort
}

stable_minor_versions() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' versions | sed -E 's/^([0-9]+\.[0-9]+).+/\1/' | sort --unique --version-sort
}

snapshot_versions() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+-snapshot$' versions | sort --unique --version-sort || echo ""
}

last_snapshot_version() {
	grep -E '^[0-9]+\.[0-9]+\.[0-9]+-snapshot$' versions | sort --unique --version-sort | tail -n 1 || echo ""
}

next_stable_version() {
	sed 's/-snapshot//' <<< $(last_snapshot_version)
}

milestone_versions() {
	grep -E "$(next_stable_version)\.(M|RC)[0-9]+$" versions | sort --unique --version-sort | tail -n 3 || echo ""
}

last_milestone_version() {
	grep -E "$(next_stable_version)\.(M|RC)[0-9]+$" versions | sort --unique --version-sort | tail -n 1 || echo ""
}

build_versions() {
	stable_minor1="$(stable_minor_versions | tail -n 3 | head -n 1)"
	stable_minor2="$(stable_minor_versions | tail -n 2 | head -n 1)"
	stable_minor3="$(stable_minor_versions | tail -n 1)"
	build_stable_minor1="$(stable_versions | grep -E "^$stable_minor1" | tail -n 1)"
	build_stable_minor2="$(stable_versions | grep -E "^$stable_minor2" | tail -n 1)"
	build_stable_minor3="$(stable_versions | grep -E "^$stable_minor3" | tail -n 3 | xargs)"
	echo "$build_stable_minor1 $build_stable_minor2 $build_stable_minor3 $(milestone_versions) $(snapshot_versions)"
}

validate_readme_constraints() {
	count=$(wc -m <README.md)
	if [ $count -gt 25000 ]; then
		echo "README.md contains $count characters which exceeds the 25000 character limit of Docker Hub"
		exit 1
	fi
}

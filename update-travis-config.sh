#!/bin/bash
set -eo pipefail

. update-functions.sh

file=.travis.yml

# Print static part of Travis configuration
print_static_configuration() {
	cat > $1 <<-'EOI'
	#
	# ------------------------------------------------------------------------------
	#          NOTE: THIS TRAVIS CONFIGURATION IS GENERATED VIA "update.sh"
	#
	#                       PLEASE DO NOT EDIT IT DIRECTLY.
	# ------------------------------------------------------------------------------
	#
	sudo: required
	language: bash
	branches:
	  only:
	    - master
	services:
	  - docker
	before_install:
	  - sudo apt-get install -y uidmap
	  - ./update-docker-files.sh
	  - ./update-img.sh
	  - docker info
	  - docker run --rm --privileged docker.io/multiarch/qemu-user-static:register --reset
	install:
	  - img build --build-arg VCS_REF=$TRAVIS_COMMIT --build-arg BUILD_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ") --build-arg VERSION=$VERSION -t docker.io/$DOCKER_REPO:$VERSION-$TARGET-$DIST $VERSION/$TARGET/$DIST
	  - docker run --rm docker.io/$DOCKER_REPO:$VERSION-$TARGET-$DIST uname -a
	after_success:
	  - docker login -u=$DOCKER_USERNAME -p=$DOCKER_PASSWORD
	  - docker push docker.io/$DOCKER_REPO:$VERSION-$TARGET-$DIST
	matrix:
	  fast_finish: true
	env:
	  matrix:
EOI
}

# Print Travis matrix environment variables
print_matrix() {
	cat >> $1 <<-EOI
	    - VERSION=$version DIST=$base TARGET=$arch
EOI
}

echo -n "Writing $file... "

# Generate the static part of the Travis configuration
print_static_configuration $file;

# Generate the matrix for building Dockerfiles
for version in $(build_versions)
do
	for base in $bases
	do
		for arch in $arches
		do
			print_matrix $file;
		done
	done
done

echo "done"

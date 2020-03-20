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
	os: linux
	dist: bionic
	language: shell
	branches:
	  only:
	    - master
	services:
	  - docker
	before_install:
	  - set -e
	  - ./update-docker-files.sh
	  - ./install-manifest-tool.sh
	  - docker info
	  - docker run --rm --privileged multiarch/qemu-user-static:register --reset
	  - source ./update-functions.sh
	  - ARCHES="$(arches $VERSION $DIST)"
	install:
	  - for ARCH in $ARCHES; do
	        docker build --build-arg VCS_REF=$TRAVIS_COMMIT --build-arg BUILD_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ") --build-arg VERSION=$VERSION -f $VERSION/$DIST/Dockerfile-$ARCH -t $DOCKER_REPO:$VERSION-$ARCH-$DIST $VERSION/$DIST;
	        docker run --rm $DOCKER_REPO:$VERSION-$ARCH-$DIST uname -a;
	    done
	after_success:
	  - if [ "$TRAVIS_BRANCH" == "master" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
	        echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin;
	        for ARCH in $ARCHES; do
	            docker push $DOCKER_REPO:$VERSION-$ARCH-$DIST;
	        done;
	        manifest-tool push from-spec $VERSION/$DIST/manifest.yml;
	    fi
	jobs:
	  fast_finish: true
	env:
	  jobs:
EOI
}

# Print Travis matrix environment variables
print_matrix() {
	cat >> $1 <<-EOI
	    - VERSION=$version DIST=$base
EOI
}

echo -n "Writing $file... "

# Generate the static part of the Travis configuration
print_static_configuration $file;

# Generate the matrix for building Dockerfiles
for version in $(build_versions)
do
	for base in $(bases)
	do
		print_matrix $file;
	done
done

echo "done"

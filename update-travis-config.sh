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
	  - ./install-img.sh
	  - ./install-manifest-tool.sh
      - wget https://github.com/sormuras/bach/raw/master/install-jdk.sh && . ./install-jdk.sh -F 11
	  - docker info
	  - docker run --rm --privileged multiarch/qemu-user-static:register --reset
	  - ARCHES="amd64 armhf arm64"
	install:
	  - for ARCH in $ARCHES; do
	        docker build --build-arg VCS_REF=$TRAVIS_COMMIT --build-arg BUILD_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ") --build-arg VERSION=$VERSION -f $VERSION/$DIST/Dockerfile-$ARCH -t $DOCKER_REPO:$VERSION-$ARCH-$DIST $VERSION/$DIST;
	        docker run --rm $DOCKER_REPO:$VERSION-$ARCH-$DIST uname -a;
	    done
	after_success:
	  - bash <(curl -s https://copilot.blackducksoftware.com/ci/travis/scripts/upload)s
	  - docker login -u=$DOCKER_USERNAME -p=$DOCKER_PASSWORD
	  - for ARCH in $ARCHES; do
	        docker push $DOCKER_REPO:$VERSION-$ARCH-$DIST;
	    done
	  - manifest-tool push from-spec $VERSION/$DIST/manifest.yml
	matrix:
	  fast_finish: true
	env:
	  matrix:
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

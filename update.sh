#!/bin/bash
set -eo pipefail

# Dockerfiles to be generated. At the moment we will focus on version 2.1.0-snapshot, because 2.0.0 is stable.
versions="2.1.0-snapshot"
arches="amd64 armhf arm64"

# Generate header
print_header() {
	cat > $1 <<-EOI
	# openhab image
	#
	# ------------------------------------------------------------------------------
	#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
	#
	#                       PLEASE DO NOT EDIT IT DIRECTLY.
	# ------------------------------------------------------------------------------
	#

	EOI
}

# Print selected image
print_baseimage() {
	case $arch in
	amd64)
		java_url="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_x64.tar.gz"
		;;
	armhf|arm64)
		java_url="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_aarch32hf.tar.gz"
		;;
	default)
		java_url="error"
		;;
	esac
	cat >> $1 <<-EOI
	FROM multiarch/debian-debootstrap:$arch-jessie
	
	# Set download urls
	ENV OPENHAB_URL="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-2.1.0-SNAPSHOT.zip"
	ENV JAVA_URL="$java_url"

	EOI
}

# Print metadata && basepackages
print_basepackages() {
	cat >> $1 <<-'EOI'
	# Set variables
	ENV \
	    APPDIR="/openhab" \
	    OPENHAB_HTTP_PORT='8080' \
	    OPENHAB_HTTPS_PORT='8443' \
	    EXTRA_JAVA_OPTS='' \
	    JAVA_HOME='/usr/lib/java-8'

	# Basic build-time metadata as defined at http://label-schema.org
	ARG BUILD_DATE
	ARG VCS_REF
	LABEL org.label-schema.build-date=$BUILD_DATE \
	    org.label-schema.docker.dockerfile="/Dockerfile" \
	    org.label-schema.license="EPL" \
	    org.label-schema.name="openHAB" \
	    org.label-schema.url="http://www.openhab.com/" \
	    org.label-schema.vcs-ref=$VCS_REF \
	    org.label-schema.vcs-type="Git" \
	    org.label-schema.vcs-url="https://github.com/openhab/openhab-docker.git"

	# Install basepackages
	RUN apt-get update && \
	    apt-get install --no-install-recommends -y \
	      ca-certificates \
	      unzip \
	      wget \
	      && rm -rf /var/lib/apt/lists/*

EOI
}

# Print 32-bit for arm64 arch
print_lib32_support_arm64() {
	cat >> $1 <<-'EOI'
	RUN dpkg --add-architecture armhf && \
	    apt-get update && \
	    apt-get install --no-install-recommends -y \
	    libc6:armhf \
	    && rm -rf /var/lib/apt/lists/*

EOI
}

# Install java
print_java() {
	cat >> $1 <<-'EOI'
	# Install java
	RUN wget -nv -O /tmp/java.tar.gz ${JAVA_URL} &&\
	    mkdir ${JAVA_HOME} && \
	    tar -xvf /tmp/java.tar.gz --strip-components=1 -C ${JAVA_HOME}

EOI
}

# Add user and install Openhab
print_openhab() {
	cat >> $1 <<-'EOI'
	# Add openhab user & handle possible device groups for different host systems
	# Container base image puts dialout on group id 20, uucp on id 10
	# GPIO Group for RPI access
	RUN adduser --disabled-password --gecos '' --home ${APPDIR} openhab &&\
	    groupadd -g 14 uucp2 &&\
	    groupadd -g 16 dialout2 &&\
	    groupadd -g 18 dialout3 &&\
	    groupadd -g 32 uucp3 &&\
	    groupadd -g 997 gpio &&\
	    adduser openhab dialout &&\
	    adduser openhab uucp &&\
	    adduser openhab uucp2 &&\
	    adduser openhab dialout2 &&\
	    adduser openhab dialout3 &&\
	    adduser openhab uucp3 &&\
	    adduser openhab gpio

	# Install openhab
	# Set permissions for openhab. Export TERM variable. See issue #30 for details!
	RUN wget -nv -O /tmp/openhab.zip ${OPENHAB_URL} &&\
	    unzip -q /tmp/openhab.zip -d ${APPDIR} &&\
	    rm /tmp/openhab.zip &&\
	    mkdir -p ${APPDIR}/userdata/logs &&\
	    touch ${APPDIR}/userdata/logs/openhab.log && \
	    cp -a ${APPDIR}/userdata ${APPDIR}/userdata.dist && \
	    cp -a ${APPDIR}/conf ${APPDIR}/conf.dist && \
	    chown -R openhab:openhab ${APPDIR} && \
	    echo "export TERM=dumb" | tee -a ~/.bashrc

	# Expose volume with configuration and userdata dir
	WORKDIR ${APPDIR}
	VOLUME ${APPDIR}/conf ${APPDIR}/userdata ${APPDIR}/addons
	EXPOSE 8080 8443 5555
	USER openhab
	CMD ["./start.sh"]

EOI
}

# Build the Dockerfiles
for version in $versions
do
	for arch in $arches
	do
		file=$version/$arch/Dockerfile
			mkdir -p `dirname $file` 2>/dev/null
			echo -n "Writing $file..."
			print_header $file;
			print_baseimage $file;
			print_basepackages $file;
			if [ "$arch" == "arm64" ]; then
				print_lib32_support_arm64 $file;
			fi
			print_java $file;
			print_openhab $file;
			echo "done"
	done
done


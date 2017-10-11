#!/bin/bash
set -eo pipefail

# Dockerfiles to be generated
versions="2.2.0-snapshot 2.1.0 2.0.0 1.8.3"
arches="i386 amd64 armhf arm64"
bases="debian alpine"

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
	# Set download url for openhab version
	case $version in
	2.2.0-snapshot)
		openhab_url="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-2.2.0-SNAPSHOT.zip"
		;;
	2.1.0)
		openhab_url="https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab%2F2.1.0%2Fopenhab-2.1.0.zip"
		;;
	2.0.0)
		openhab_url="https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab%2F2.0.0%2Fopenhab-2.0.0.zip"
		;;
	1.8.3)
		openhab_url="https://bintray.com/artifact/download/openhab/bin/distribution-1.8.3-runtime.zip"
		;;
	default)
		openhab_url="error"
		;;
	esac

	# Set java download based on architecture
	case $arch in
	i386|amd64)
		java_url="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_x64.tar.gz"
		;;
	armhf|arm64)
		java_url="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_aarch32hf.tar.gz"
		;;
	default)
		java_url="error"
		;;
	esac

	# Set docker base image based on distributions
	case $base in
	debian)
		base_image="debian-debootstrap:$arch-jessie"
		;;
	alpine)
		base_image="alpine:$arch-latest-stable"
		;;
	default)
		base_image="error"
		;;
	esac

	cat >> $1 <<-EOI
	FROM multiarch/$base_image

	MAINTAINER openHAB <info@openhabfoundation.org>

	# Set download urls
	ENV JAVA_URL="$java_url"
	ENV OPENHAB_URL="$openhab_url"
	ENV OPENHAB_VERSION="$version"

	EOI
}

# Print metadata
print_basemetadata() {
	cat >> $1 <<-'EOI'
	# Set variables
	ENV \
	    APPDIR="/openhab" \
	    EXTRA_JAVA_OPTS="" \
	    OPENHAB_HTTP_PORT="8080" \
	    OPENHAB_HTTPS_PORT="8443"

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
	    org.label-schema.vcs-url="https://github.com/openhab/openhab-docker.git" \
			maintainer="openHAB <info@openhabfoundation.org>"

	# Set locales
	ENV \
	    LC_ALL=en_US.UTF-8 \
	    LANG=en_US.UTF-8 \
	    LANGUAGE=en_US.UTF-8

EOI
}

# Print basepackages for debian
print_basepackages() {
	cat >> $1 <<-'EOI'
	# Install basepackages
	RUN apt-get update && \
			apt-get install --no-install-recommends -y \
				ca-certificates \
				fontconfig \
				locales \
				locales-all \
				libpcap-dev \
				netbase \
				unzip \
				wget \
				&& rm -rf /var/lib/apt/lists/*
	ENV DEBIAN_FRONTEND=noninteractive

EOI
}

# Print basepackages for alpine
print_basepackages_alpine() {
	cat >> $1 <<-'EOI'
	# Install basepackages
	RUN apk update && \
			apk add \
				ca-certificates \
				fontconfig \
				libpcap-dev \
				unzip \
				dpkg \
				gnupg \
				wget \
				bash \
				shadow

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

# Install gosu
print_gosu() {
	cat >> $1 <<-'EOI'
	# Install gosu
	ENV GOSU_VERSION 1.10
	RUN set -x \
			&& dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
			&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
	    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
	    && export GNUPGHOME="$(mktemp -d)" \
	    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	    && chmod +x /usr/local/bin/gosu

EOI
}

# Install su-exec
print_su-exec() {
	cat >> $1 <<-'EOI'
  # Install su-exec
	RUN apk add su-exec

EOI
}

# Install java for debian
print_java() {
	cat >> $1 <<-'EOI'
	# Install java
	ENV JAVA_HOME='/usr/lib/java-8'
	RUN wget -nv -O /tmp/java.tar.gz ${JAVA_URL} &&\
	    mkdir ${JAVA_HOME} && \
	    tar -xvf /tmp/java.tar.gz --strip-components=1 -C ${JAVA_HOME} && \
	    update-alternatives --install /usr/bin/java java ${JAVA_HOME}/bin/java 50 && \
	    update-alternatives --install /usr/bin/javac javac ${JAVA_HOME}/bin/javac 50

EOI
}

# Install java for alpine
print_java_alpine() {
	cat >> $1 <<-'EOI'
  # Install java
	RUN apk add openjdk8

EOI
}

# Install openhab for 2.0.0 and newer
print_openhab_install() {
	cat >> $1 <<-'EOI'
	# Install openhab
	# Set permissions for openhab. Export TERM variable. See issue #30 for details!
	RUN wget -nv -O /tmp/openhab.zip ${OPENHAB_URL} &&\
	    unzip -q /tmp/openhab.zip -d ${APPDIR} &&\
	    rm /tmp/openhab.zip &&\
	    mkdir -p ${APPDIR}/userdata/logs &&\
	    touch ${APPDIR}/userdata/logs/openhab.log && \
	    cp -a ${APPDIR}/userdata ${APPDIR}/userdata.dist && \
	    cp -a ${APPDIR}/conf ${APPDIR}/conf.dist && \
	    echo "export TERM=dumb" | tee -a ~/.bashrc

EOI
}

# Install openhab for 1.8.3
print_openhab_install_old() {
	cat >> $1 <<-'EOI'
	# Install openhab
	RUN wget -nv -O /tmp/openhab.zip ${OPENHAB_URL} &&\
	    unzip -q /tmp/openhab.zip -d ${APPDIR} &&\
	    rm /tmp/openhab.zip &&\
	    cp -a ${APPDIR}/configurations ${APPDIR}/configurations.dist && \
	    echo "export TERM=dumb" | tee -a ~/.bashrc

EOI
}

# Add volumes for 2.0.0 and newer
print_volumes() {
	cat >> $1 <<-'EOI'
	# Expose volume with configuration and userdata dir
	VOLUME ${APPDIR}/conf ${APPDIR}/userdata ${APPDIR}/addons

EOI
}

# Add volumes for 1.8.3
print_volumes_old() {
	cat >> $1 <<-'EOI'
	# Expose volume with configuration and userdata dir
	VOLUME ${APPDIR}/configurations ${APPDIR}/addons

EOI
}

# Set working directory, expose and entrypoint
print_entrypoint() {
	cat >> $1 <<-'EOI'
	# Set working directory, expose and entrypoint
	WORKDIR ${APPDIR}
	EXPOSE 8080 8443 5555
	COPY entrypoint.sh /
	RUN chmod +x /entrypoint.sh
	ENTRYPOINT ["/entrypoint.sh"]
	# Execute command

EOI
}

# Set command
print_command() {
	case $base in
	debian)
		cat >> $1 <<-'EOI'
		CMD ["gosu", "openhab", "./start.sh"]
		EOI
		;;
	alpine)
		cat >> $1 <<-'EOI'
		CMD ["su-exec", "openhab", "./start.sh"]
		EOI
		;;
	default)
		cat >> $1 <<-'EOI'
		CMD ["./start.sh"]
		EOI
		;;
	esac
}

# Build the Dockerfiles
for version in $versions
do
	for base in $bases
	do
		for arch in $arches
		do
			file=$version/$arch/$base/Dockerfile
				mkdir -p `dirname $file` 2>/dev/null
				echo -n "Writing $file..."
				print_header $file;
				print_baseimage $file;
				print_basemetadata $file;
				if [ "$base" == "alpine" ]; then
					print_basepackages_alpine $file;
					print_java_alpine $file;
					print_su-exec $file;
				else
					print_basepackages $file;
					print_java $file;
					print_gosu $file;
				fi
				if [ "$arch" == "arm64" ] && [ "$base" == "debian" ]; then
					print_lib32_support_arm64 $file;
				fi
				if [ "$version" == "1.8.3" ]; then
					print_openhab_install_old $file;
					print_volumes_old $file
				else
					print_openhab_install $file;
					print_volumes $file
				fi
				print_entrypoint $file
				print_command $file
				if [ "$base" == "alpine" ]; then
					cp entrypoint_alpine.sh $version/$arch/$base/entrypoint.sh
				else
					cp entrypoint_debian.sh $version/$arch/$base/entrypoint.sh
				fi
				echo "done"
		done
	done
done

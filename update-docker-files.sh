#!/bin/bash
set -eo pipefail

. update-functions.sh

# Distribution download URLs
openhab_release_url='https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab%2F${version}%2Fopenhab-${version}.zip'
openhab_milestone_url='https://openhab.jfrog.io/openhab/libs-milestone-local/org/openhab/distro/openhab/${version}/openhab-${version}.zip'
openhab2_snapshot_url='https://ci.openhab.org/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-${version}.zip'
openhab3_snapshot_url='https://ci.openhab.org/job/openHAB3-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-${version}.zip'

# Zulu 8 download URLs
zulu8_amd64_url='https://cdn.azul.com/zulu/bin/zulu8.50.0.51-ca-jdk8.0.275-linux_x64.tar.gz'
zulu8_armhf_url='https://cdn.azul.com/zulu-embedded/bin/zulu8.50.51.263-ca-jdk8.0.275-linux_aarch32hf.tar.gz'
zulu8_arm64_url='https://cdn.azul.com/zulu-embedded/bin/zulu8.50.51.263-ca-jdk8.0.275-linux_aarch64.tar.gz'

# Zulu 11 download URLs
zulu11_amd64_url='https://cdn.azul.com/zulu/bin/zulu11.43.21-ca-jdk11.0.9-linux_x64.tar.gz'
zulu11_armhf_url='https://cdn.azul.com/zulu-embedded/bin/zulu11.43.88-ca-jdk11.0.9-linux_aarch32hf.tar.gz'
zulu11_arm64_url='https://cdn.azul.com/zulu-embedded/bin/zulu11.43.88-ca-jdk11.0.9-linux_aarch64.tar.gz'

zulu_url_vars=(zulu8_amd64_url zulu8_armhf_url zulu8_arm64_url zulu11_amd64_url zulu11_armhf_url zulu11_arm64_url)

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
	# Set Java version based on openHAB versions
	case $version in
	2.*) java_version="8";;
	3.*) java_version="11";;
	*)   java_version="error";;
	esac

	# Set Docker base image based on distributions
	case $base in
	alpine) base_image="alpine:3.12.2";;
	debian) base_image="debian:10.7-slim";;
	*)      base_image="error";;
	esac

	cat >> $1 <<-EOI
	FROM $base_image

	# Set version variables
	ENV \\
	    JAVA_VERSION="$java_version" \\
	    OPENHAB_VERSION="$version"

EOI
}

# Print metadata
print_basemetadata() {
	cat >> $1 <<-'EOI'
	# Set other variables
	ENV \
	    CRYPTO_POLICY="limited" \
	    EXTRA_JAVA_OPTS="" \
	    GROUP_ID="9001" \
	    KARAF_EXEC="exec" \
	    LC_ALL="en_US.UTF-8" \
	    LANG="en_US.UTF-8" \
	    LANGUAGE="en_US.UTF-8" \
	    OPENHAB_BACKUPS="/openhab/userdata/backup" \
	    OPENHAB_CONF="/openhab/conf" \
	    OPENHAB_HOME="/openhab" \
	    OPENHAB_HTTP_PORT="8080" \
	    OPENHAB_HTTPS_PORT="8443" \
	    OPENHAB_LOGDIR="/openhab/userdata/logs" \
	    OPENHAB_USERDATA="/openhab/userdata" \
	    USER_ID="9001"

	# Set arguments on build
	ARG BUILD_DATE
	ARG VCS_REF
	ARG VERSION

	# Basic build-time metadata as defined at http://label-schema.org
	LABEL org.label-schema.build-date=$BUILD_DATE \
	    org.label-schema.docker.dockerfile="/Dockerfile" \
	    org.label-schema.license="EPL-2.0" \
	    org.label-schema.name="openHAB" \
	    org.label-schema.vendor="openHAB Foundation e.V." \
	    org.label-schema.version=$VERSION \
	    org.label-schema.description="An open source, technology agnostic home automation platform" \
	    org.label-schema.url="https://www.openhab.com/" \
	    org.label-schema.vcs-ref=$VCS_REF \
	    org.label-schema.vcs-type="Git" \
	    org.label-schema.vcs-url="https://github.com/openhab/openhab-docker.git" \
	    maintainer="openHAB <info@openhabfoundation.org>"

EOI
}

# Print basepackages for Alpine
print_basepackages_alpine() {
	cat >> $1 <<-'EOI'
	# Install basepackages
	RUN apk update --no-cache && \
	    apk add --no-cache \
	        arping \
	        bash \
	        ca-certificates \
	        curl \
	        fontconfig \
	        libcap \
	        nss \
	        shadow \
	        su-exec \
	        tini \
	        ttf-dejavu \
	        openjdk${JAVA_VERSION} \
	        unzip \
	        wget \
	        zip && \
	    chmod u+s /usr/sbin/arping && \
	    rm -rf /var/cache/apk/*

EOI
}

# Print basepackages for Debian
print_basepackages_debian() {
	cat >> $1 <<-'EOI'
	# Install basepackages
	RUN apt-get update && \
	    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
	        arping \
	        ca-certificates \
	        curl \
	        fontconfig \
	        gosu \
	        libcap2-bin \
	        locales \
	        locales-all \
	        netbase \
	        procps \
	        tini \
	        unzip \
	        wget \
	        zip && \
	    chmod u+s /usr/sbin/arping && \
	    ln -s -f /bin/true /usr/bin/chfn && \
	    apt-get clean && \
	    rm -rf /var/lib/apt/lists/*

EOI
}

# Configure Java for Alpine
print_java_alpine() {
	cat >> $1 <<-'EOI'
	# Limit JDK crypto policy by default to comply with local laws which may prohibit use of unlimited strength cryptography
	ENV JAVA_HOME='/usr/lib/jvm/default-jvm'
	RUN if [ "${JAVA_VERSION}" = "8" ]; then \
	        sed -i 's/^crypto.policy=unlimited/crypto.policy=limited/' "${JAVA_HOME}/jre/lib/security/java.security"; \
	    elif [ "${JAVA_VERSION}" = "11" ]; then \
	        sed -i 's/^crypto.policy=unlimited/crypto.policy=limited/' "${JAVA_HOME}/conf/security/java.security"; \
	    fi

EOI
}

# Install Java for Debian
print_java_debian() {
	cat >> $1 <<-'EOI'
	# Install java
	ENV JAVA_HOME='/usr/lib/jvm/default-jvm'
	# Limit JDK crypto policy by default to comply with local laws which may prohibit use of unlimited strength cryptography
	RUN mkdir -p "${JAVA_HOME}" && \
EOI

	for zulu_url_var in ${zulu_url_vars[@]}
	do
		cat >> $1 <<-EOI
		    $zulu_url_var='${!zulu_url_var}' && \\
EOI
	done

	cat >> $1 <<-'EOI'
	    url_var="zulu${JAVA_VERSION}_$(dpkg --print-architecture)_url" && \
	    eval "java_url=\$$url_var" && \
	    wget -nv -O /tmp/java.tar.gz "${java_url}" && \
	    tar --exclude='demo' --exclude='sample' --exclude='src.zip' -xf /tmp/java.tar.gz --strip-components=1 -C "${JAVA_HOME}" && \
	    if [ "${JAVA_VERSION}" = "8" ]; then \
	        sed -i 's/^#crypto.policy=unlimited/crypto.policy=limited/' "${JAVA_HOME}/jre/lib/security/java.security"; \
	    elif [ "${JAVA_VERSION}" = "11" ]; then \
	        sed -i 's/^crypto.policy=unlimited/crypto.policy=limited/' "${JAVA_HOME}/conf/security/java.security"; \
	    fi && \
	    rm /tmp/java.tar.gz && \
	    update-alternatives --install /usr/bin/java java "${JAVA_HOME}/bin/java" 50 && \
	    update-alternatives --install /usr/bin/javac javac "${JAVA_HOME}/bin/javac" 50

EOI
}

print_openhab_install() {
	case $version in
	*.M*|*.RC*)
		openhab_url=$(eval "echo $openhab_milestone_url")
		;;
	2.*-snapshot)
		openhab_url=$(eval "echo $openhab2_snapshot_url" | sed 's/snapshot/SNAPSHOT/g')
		;;
	3.*-snapshot)
		openhab_url=$(eval "echo $openhab3_snapshot_url" | sed 's/snapshot/SNAPSHOT/g')
		;;
	*)
		openhab_url=$(eval "echo $openhab_release_url")
		;;
	esac

	cat >> $1 <<-'EOI'
	# Install openHAB
	# Set permissions for openHAB. Export TERM variable. See issue #30 for details!
EOI

	cat >> $1 <<-EOI
	RUN wget -nv -O /tmp/openhab.zip "${openhab_url}" && \\
EOI

	cat >> $1 <<-'EOI'
	    unzip -q /tmp/openhab.zip -d "${OPENHAB_HOME}" -x "*.bat" "*.ps1" "*.psm1" && \
	    rm /tmp/openhab.zip && \
	    if [ ! -f "${OPENHAB_HOME}/runtime/bin/update.lst" ]; then touch "${OPENHAB_HOME}/runtime/bin/update.lst"; fi && \
	    if [ ! -f "${OPENHAB_HOME}/runtime/bin/userdata_sysfiles.lst" ]; then wget -nv -O "${OPENHAB_HOME}/runtime/bin/userdata_sysfiles.lst" "https://raw.githubusercontent.com/openhab/openhab-distro/2.4.0/distributions/openhab/src/main/resources/bin/userdata_sysfiles.lst"; fi && \
	    mkdir -p "${OPENHAB_LOGDIR}" && \
	    touch "${OPENHAB_LOGDIR}/openhab.log" && \
	    mkdir -p "${OPENHAB_HOME}/dist" && \
	    cp -a "${OPENHAB_CONF}" "${OPENHAB_USERDATA}" "${OPENHAB_HOME}/dist" && \
	    echo 'export TERM=${TERM:=dumb}' | tee -a ~/.bashrc
	COPY update.sh ${OPENHAB_HOME}/runtime/bin/update
	RUN chmod +x ${OPENHAB_HOME}/runtime/bin/update

EOI
}

# Add volumes for openHAB
print_volumes() {
	cat >> $1 <<-'EOI'
	# Expose volume with configuration and userdata dir
	VOLUME ${OPENHAB_CONF} ${OPENHAB_USERDATA} ${OPENHAB_HOME}/addons

EOI
}

print_expose_ports() {
	cat >> $1 <<-'EOI'
	# Expose HTTP, HTTPS, Console and LSP ports
	EXPOSE 8080 8443 8101 5007

EOI
}

# Set working directory and entrypoint
print_entrypoint() {
	cat >> $1 <<-'EOI'
	# Set working directory and entrypoint
	WORKDIR ${OPENHAB_HOME}
	COPY entrypoint.sh /
	RUN chmod +x /entrypoint.sh
	ENTRYPOINT ["/entrypoint.sh"]

	# Execute command
EOI
}

# Set command
print_command() {
	case $base in
	alpine)
		cat >> $1 <<-'EOI'
		CMD ["su-exec", "openhab", "tini", "-s", "./start.sh"]
		EOI
		;;
	debian)
		cat >> $1 <<-'EOI'
		CMD ["gosu", "openhab", "tini", "-s", "./start.sh"]
		EOI
		;;
	*)
		cat >> $1 <<-'EOI'
		CMD ["./start.sh"]
		EOI
		;;
	esac
}

# Generate Dockerfile
generate_docker_file() {
	file="$version/$base/Dockerfile"
	mkdir -p $(dirname $file) 2>/dev/null
	echo -n "Writing $file... "
	print_header $file;
	print_baseimage $file;
	print_basemetadata $file;

	case $base in
	alpine)
		print_basepackages_alpine $file;
		print_java_alpine $file;
		;;
	debian)
		print_basepackages_debian $file;
		print_java_debian $file;
		;;
	esac

	print_openhab_install $file;
	print_volumes $file
	print_expose_ports $file
	print_entrypoint $file
	print_command $file

	echo "done"
}

# Remove previously generated container files
rm -rf ./2.* ./3.*

# Generate new container files
for version in $(build_versions)
do
	for base in $(bases)
	do
		# Generate Dockerfile
		generate_docker_file

		# Copy base specific entrypoint.sh
		case $base in
			alpine) cp "entrypoint-alpine.sh" "$version/$base/entrypoint.sh";;
			debian) cp "entrypoint-debian.sh" "$version/$base/entrypoint.sh";;
		esac

		# Copy update script
		cp "openhab-update.sh" "$version/$base/update.sh"
	done
done

#!/bin/bash
set -eo pipefail

. update-functions.sh

# Distribution download URLs
openhab1_release_url='https://bintray.com/artifact/download/openhab/bin/distribution-${version}-runtime.zip'
openhab2_release_url='https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab%2F${version}%2Fopenhab-${version}.zip'
openhab2_milestone_url='https://openhab.jfrog.io/openhab/libs-milestone-local/org/openhab/distro/openhab/${version}/openhab-${version}.zip'
openhab2_snapshot_url='https://ci.openhab.org/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-${version}.zip'
openhab3_snapshot_url='https://ci.openhab.org/job/openHAB3-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-${version}.zip'

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
	# Set download URL for openHAB version
	case $version in
	1.*)
		openhab_url=$(eval "echo $openhab1_release_url")
		;;
	2.*.M*|2.*.RC*|3.*.M*|3.*.RC*)
		openhab_url=$(eval "echo $openhab2_milestone_url")
		;;
	2.*-snapshot)
		openhab_url=$(eval "echo $openhab2_snapshot_url" | sed 's/snapshot/SNAPSHOT/g')
		;;
	3.*-snapshot)
		openhab_url=$(eval "echo $openhab3_snapshot_url" | sed 's/snapshot/SNAPSHOT/g')
		;;
	2.*|3.*)
		openhab_url=$(eval "echo $openhab2_release_url")
		;;
	default)
		openhab_url="error"
		;;
	esac

	# Set download URL for openHAB version
	case $version in
	1.*|2.*)
		java_version="8"
		case $arch in
		amd64)
			java_url="https://cdn.azul.com/zulu/bin/zulu8.42.0.23-ca-jdk8.0.232-linux_x64.tar.gz"
			;;
		armhf)
			java_url="https://cdn.azul.com/zulu-embedded/bin/zulu8.42.0.195-ca-jdk1.8.0_232-linux_aarch32hf.tar.gz"
			;;
		arm64)
			java_url="https://cdn.azul.com/zulu-embedded/bin/zulu8.42.0.195-ca-jdk1.8.0_232-linux_aarch64.tar.gz"
			;;
		default)
			java_url="error"
			;;
		esac
		;;
	3.*)
		java_version="11"
		case $arch in
		amd64)
			java_url="https://cdn.azul.com/zulu/bin/zulu11.37.17-ca-jdk11.0.6-linux_x64.tar.gz"
			;;
		armhf)
			java_url="https://cdn.azul.com/zulu-embedded/bin/zulu11.37.48-ca-jdk11.0.6-linux_aarch32hf.tar.gz"
			;;
		arm64)
			java_url="https://cdn.azul.com/zulu-embedded/bin/zulu11.37.48-ca-jdk11.0.6-linux_aarch64.tar.gz"
			;;
		default)
			java_url="error"
			;;
		esac
		;;
	default)
	        java_version="error"
		java_url="error"
		;;
	esac

	# Set Docker base image based on distributions
	case $base in
	alpine)
		base_image="alpine:$arch-v3.11"
		;;
	debian)
		base_image="debian-debootstrap:$arch-buster"
		;;
	default)
		base_image="error"
		;;
	esac

	cat >> $1 <<-EOI
	FROM multiarch/$base_image

	# Set download urls
	ENV \\
	    JAVA_URL="$java_url" \\
	    JAVA_VERSION="$java_version" \\
	    OPENHAB_URL="$openhab_url" \\
	    OPENHAB_VERSION="$version"

EOI
}

# Print metadata
print_basemetadata() {
	cat >> $1 <<-'EOI'
	# Set variables and locales
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
	RUN apk upgrade --no-cache && \
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
	RUN wget -nv -O /tmp/java.tar.gz "${JAVA_URL}" && \
	    mkdir -p "${JAVA_HOME}" && \
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

# Install openHAB 1.x
print_openhab_install_oh1() {
	cat >> $1 <<-'EOI'
	# Install openHAB
	RUN wget -nv -O /tmp/openhab.zip "${OPENHAB_URL}" && \
	    unzip -q /tmp/openhab.zip -d "${OPENHAB_HOME}" -x "*.bat" && \
	    rm /tmp/openhab.zip && \
	    mkdir -p "${OPENHAB_HOME}/dist" && \
	    cp -a "${OPENHAB_HOME}/configurations" "${OPENHAB_HOME}/dist" && \
	    echo 'export TERM=${TERM:=dumb}' | tee -a ~/.bashrc

EOI
}

# Install openHAB 2.x
print_openhab_install_oh2() {
	cat >> $1 <<-'EOI'
	# Install openHAB
	# Set permissions for openHAB. Export TERM variable. See issue #30 for details!
	RUN wget -nv -O /tmp/openhab.zip "${OPENHAB_URL}" && \
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

# Add volumes for openHAB 1.x
print_volumes_oh1() {
	cat >> $1 <<-'EOI'
	# Expose volume with configuration and userdata dir
	VOLUME ${OPENHAB_HOME}/configurations ${OPENHAB_HOME}/addons

EOI
}

# Add volumes for openHAB 2.x
print_volumes_oh2() {
	cat >> $1 <<-'EOI'
	# Expose volume with configuration and userdata dir
	VOLUME ${OPENHAB_CONF} ${OPENHAB_USERDATA} ${OPENHAB_HOME}/addons

EOI
}

print_expose_ports() {
	case $version in
	1.*)
		expose_comment="Expose HTTP and HTTPS ports"
		expose_ports="8080 8443"
		;;
	2.0.0|2.1.0)
		expose_comment="Expose HTTP, HTTPS and Console ports"
		expose_ports="8080 8443 8101"
		;;
	2.*|3.*)
		expose_comment="Expose HTTP, HTTPS, Console and LSP ports"
		expose_ports="8080 8443 8101 5007"
		;;
	default)
		expose_comment="Error"
		expose_ports="error"
		;;
	esac

	cat >> $1 <<-EOI
	# $expose_comment
	EXPOSE $expose_ports

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
	default)
		cat >> $1 <<-'EOI'
		CMD ["./start.sh"]
		EOI
		;;
	esac
}

generate_docker_files() {
	for arch in $(arches)
	do
		# Generate Dockerfile
		file="$version/$base/Dockerfile-$arch"
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

		case $version in
		1.*)
			print_openhab_install_oh1 $file;
			print_volumes_oh1 $file
			;;
		2.*|3.*)
			print_openhab_install_oh2 $file;
			print_volumes_oh2 $file
			;;
		esac

		print_expose_ports $file
		print_entrypoint $file
		print_command $file

		echo "done"
	done
}

generate_manifest() {
	tags=()

	if [ "$base" == "debian" ]; then
		tags+=("'$version'")
	fi

	if [ "$version" == "$(last_stable_version)" ]; then
		if [ "$base" == "debian" ]; then
			tags+=("'latest'")
		fi
		tags+=("'latest-$base'")
	fi

	milestone_maturity_version="$(last_milestone_version)"
	if [ "$milestone_maturity_version" == "" ]; then
		milestone_maturity_version="$(last_stable_version)"
	fi

	if [ "$version" == "$milestone_maturity_version" ]; then
		if [ "$base" == "debian" ]; then
			tags+=("'milestone'")
		fi
		tags+=("'milestone-$base'")
	fi

	if [ "$version" == "$(snapshot_version)" ]; then
		if [ "$base" == "debian" ]; then
			tags+=("'snapshot'")
		fi
		tags+=("'snapshot-$base'")
	fi

	tags=$(IFS=,; echo "${tags[*]}")
	tags="${tags//,/, }"

	cat >> $1 <<-EOI
	image: $(docker_repo):$version-$base
	tags: [$tags]
	manifests:
	  -
	    image: $(docker_repo):$version-amd64-$base
	    platform:
	      architecture: amd64
	      os: linux
	  -
	    image: $(docker_repo):$version-armhf-$base
	    platform:
	      architecture: arm
	      os: linux
	  -
	    image: $(docker_repo):$version-arm64-$base
	    platform:
	      architecture: arm64
	      os: linux
EOI
}

# Remove previously generated container files
rm -rf ./1.* ./2.* ./3.*

# Generate new container files
for version in $(build_versions)
do
	for base in $(bases)
	do
		# Generate Dockerfile per architecture
		generate_docker_files

		# Generate multi-architecture manifest
		generate_manifest "$version/$base/manifest.yml"

		# Copy base specific entrypoint.sh
		case $base in
			alpine) cp "entrypoint-alpine.sh" "$version/$base/entrypoint.sh";;
			debian) cp "entrypoint-debian.sh" "$version/$base/entrypoint.sh";;
		esac

		# Copy version specific update script
		case $version in
			2.*|3.*) cp "openhab2-update.sh" "$version/$base/update.sh";;
		esac
	done
done

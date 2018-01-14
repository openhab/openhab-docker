#!/bin/bash
set -eo pipefail

# Dockerfiles to be generated
versions="2.3.0-snapshot 2.2.0 2.1.0 2.0.0 1.8.3"
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
	2.3.0-snapshot)
		openhab_url="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-2.3.0-SNAPSHOT.zip"
		;;
	2.2.0)
		openhab_url="https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab%2F2.2.0%2Fopenhab-2.2.0.zip"
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
		base_image="debian-debootstrap:$arch-stretch"
		;;
	alpine)
		base_image="alpine:$arch-v3.7"
		;;
	default)
		base_image="error"
		;;
	esac

	cat >> $1 <<-EOI
	FROM multiarch/$base_image

	# Set download urls
	ENV \
	    JAVA_URL="$java_url" \
	    OPENHAB_URL="$openhab_url" \
	    OPENHAB_VERSION="$version"

	EOI
}

# Print metadata
print_basemetadata() {
	cat >> $1 <<-'EOI'
	# Set variables and locales
	ENV \
	    APPDIR="/openhab" \
	    EXTRA_JAVA_OPTS="" \
	    OPENHAB_HTTP_PORT="8080" \
	    OPENHAB_HTTPS_PORT="8443" \
	    LC_ALL="en_US.UTF-8" \
	    LANG="en_US.UTF-8" \
	    LANGUAGE="en_US.UTF-8" \
	    CRYPTO_POLICY="limited"

	# Set arguments on build
	ARG BUILD_DATE
	ARG VCS_REF
	ARG VERSION

	# Basic build-time metadata as defined at http://label-schema.org
	LABEL org.label-schema.build-date=$BUILD_DATE \
	    org.label-schema.docker.dockerfile="/Dockerfile" \
	    org.label-schema.license="EPL" \
	    org.label-schema.name="openHAB" \
	    org.label-schema.vendor="openHAB Foundation e.V." \
	    org.label-schema.version=$VERSION \
	    org.label-schema.description="An open source, technology agnostic home automation platform" \
	    org.label-schema.url="http://www.openhab.com/" \
	    org.label-schema.vcs-ref=$VCS_REF \
	    org.label-schema.vcs-type="Git" \
	    org.label-schema.vcs-url="https://github.com/openhab/openhab-docker.git" \
	    maintainer="openHAB <info@openhabfoundation.org>"

EOI
}

# Print basepackages for debian
print_basepackages() {
	cat >> $1 <<-'EOI'
	# Install basepackages
	RUN apt-get update && \
	    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
	    ca-certificates \
	    dirmngr \
	    fontconfig \
	    gnupg \
	    libpcap-dev \
	    locales \
	    locales-all \
	    netbase \
	    unzip \
	    wget \
	    zip && \
	    ln -s -f /bin/true /usr/bin/chfn

EOI
}

# Print basepackages for alpine
print_basepackages_alpine() {
	cat >> $1 <<-'EOI'
	# Install basepackages
	RUN apk upgrade --no-cache && \
	    apk add --no-cache --virtual build-dependencies dpkg gnupg && \
	    apk add --no-cache \
	    bash \
	    ca-certificates \
	    fontconfig \
	    libpcap-dev \
	    shadow \
	    su-exec \
	    ttf-dejavu \
	    openjdk8 \
	    unzip \
	    wget \
	    zip

EOI
}

# Print cleanup for debian
print_cleanup() {
	cat >> $1 <<-'EOI'
	# Reduce image size by removing files that are used only for building the image
	RUN DEBIAN_FRONTEND=noninteractive apt-get remove -y dirmngr gnupg && \
	    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y && \
	    rm -rf /var/lib/apt/lists/*

EOI
}

# Print cleanup for alpine
print_cleanup_alpine() {
	cat >> $1 <<-'EOI'
	# Reduce image size by removing files that are used only for building the image
	RUN apk del build-dependencies && \
	    rm -rf /var/cache/apk/*

EOI
}

# Print 32-bit for arm64 arch
print_lib32_support_arm64() {
	cat >> $1 <<-'EOI'
	RUN dpkg --add-architecture armhf && \
	    apt-get update && \
	    apt-get install --no-install-recommends -y \
	    libc6:armhf

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
	    && export GNUPGHOME \
	    && GNUPGHOME="$(mktemp -d)" \
	    && GPG_KEY="B42F6819007F00F88E364FD4036A9C25BF357DD4" \
	    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys $GPG_KEY \
	       || gpg --keyserver pgp.mit.edu --recv-keys $GPG_KEY \
	       || gpg --keyserver keyserver.pgp.com --recv-keys $GPG_KEY \
	    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	    && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
	    && chmod +x /usr/local/bin/gosu

EOI
}

# Install java for debian
print_java() {
	cat >> $1 <<-'EOI'
	# Install java
	ENV JAVA_HOME='/usr/lib/java-8'
	RUN wget -nv -O /tmp/java.tar.gz ${JAVA_URL} && \
	    mkdir ${JAVA_HOME} && \
	    tar --exclude='demo' --exclude='sample' --exclude='src.zip' -xvf /tmp/java.tar.gz --strip-components=1 -C ${JAVA_HOME} && \
	    rm /tmp/java.tar.gz && \
	    update-alternatives --install /usr/bin/java java ${JAVA_HOME}/bin/java 50 && \
	    update-alternatives --install /usr/bin/javac javac ${JAVA_HOME}/bin/javac 50

EOI
}

# Configure java for alpine
print_java_alpine() {
	cat >> $1 <<-'EOI'
	# Limit OpenJDK crypto policy by default to comply with local laws which may prohibit use of unlimited strength cryptography
	ENV JAVA_HOME='/usr/lib/jvm/java-1.8-openjdk'
	RUN rm -r "$JAVA_HOME/jre/lib/security/policy/unlimited" && \
	    sed -i 's/^crypto.policy=unlimited/crypto.policy=limited/' "$JAVA_HOME/jre/lib/security/java.security"

EOI
}

# Install openhab for 2.0.0 and newer
print_openhab_install() {
	cat >> $1 <<-'EOI'
	# Install openhab
	# Set permissions for openhab. Export TERM variable. See issue #30 for details!
	RUN wget -nv -O /tmp/openhab.zip ${OPENHAB_URL} && \
	    unzip -q /tmp/openhab.zip -d ${APPDIR} && \
	    rm /tmp/openhab.zip && \
	    mkdir -p ${APPDIR}/userdata/logs && \
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
	RUN wget -nv -O /tmp/openhab.zip ${OPENHAB_URL} && \
	    unzip -q /tmp/openhab.zip -d ${APPDIR} && \
	    rm /tmp/openhab.zip && \
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

print_expose_ports() {
	case $version in
	1.8.3)
		expose_comment="Expose HTTP and HTTPS ports"
		expose_ports="8080 8443"
		;;
	2.0.0|2.1.0)
		expose_comment="Expose HTTP, HTTPS and Console ports"
		expose_ports="8080 8443 8101"
		;;
	2.2.0|2.3.0-snapshot)
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
	WORKDIR ${APPDIR}
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
				mkdir -p $(dirname $file) 2>/dev/null
				echo -n "Writing $file..."
				print_header $file;
				print_baseimage $file;
				print_basemetadata $file;
				if [ "$base" == "alpine" ]; then
					print_basepackages_alpine $file;
					print_java_alpine $file;
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
				if [ "$base" == "alpine" ]; then
					print_cleanup_alpine $file;
				else
					print_cleanup $file;
				fi
				print_expose_ports $file
				print_entrypoint $file
				print_command $file

				dstFile=$version/$arch/$base/entrypoint.sh
				if [ "$base" == "alpine" ]; then
					cp entrypoint_alpine.sh $dstFile
					# remove bug fix for version 2 from entrypoint_alpine.sh
					if [ "$version" == "1.8.3" ]; then
						line=$(sed "/rm -f \/openhab\/userdata\/tmp\/instances\/instance.properties/=; d" entrypoint_alpine.sh)
						sed -i "$((line-7)),${line}"d $dstFile
					fi
				else
					cp entrypoint_debian.sh $dstFile
				fi
				echo "done"
		done
	done
done


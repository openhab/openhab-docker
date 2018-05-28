# openhab image
#
# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#
FROM multiarch/debian-debootstrap:armhf-stretch

# Set download urls
ENV 	    JAVA_URL="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_aarch32hf.tar.gz" 	    OPENHAB_URL="https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab%2F2.3.0%2Fopenhab-2.3.0.zip" 	    OPENHAB_VERSION="2.3.0"

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

# Install java
ENV JAVA_HOME='/usr/lib/java-8'
RUN wget -nv -O /tmp/java.tar.gz ${JAVA_URL} && \
    mkdir ${JAVA_HOME} && \
    tar --exclude='demo' --exclude='sample' --exclude='src.zip' -xvf /tmp/java.tar.gz --strip-components=1 -C ${JAVA_HOME} && \
    rm /tmp/java.tar.gz && \
    update-alternatives --install /usr/bin/java java ${JAVA_HOME}/bin/java 50 && \
    update-alternatives --install /usr/bin/javac javac ${JAVA_HOME}/bin/javac 50

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

# Expose volume with configuration and userdata dir
VOLUME ${APPDIR}/conf ${APPDIR}/userdata ${APPDIR}/addons

# Reduce image size by removing files that are used only for building the image
RUN DEBIAN_FRONTEND=noninteractive apt-get remove -y dirmngr gnupg && \
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Expose HTTP, HTTPS, Console and LSP ports
EXPOSE 8080 8443 8101 5007

# Set working directory and entrypoint
WORKDIR ${APPDIR}
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Execute command
CMD ["gosu", "openhab", "./start.sh"]

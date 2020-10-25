# openhab image
#
# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#
FROM debian:10.5-slim

# Set version variables
ENV \
    JAVA_VERSION="8" \
    OPENHAB_VERSION="2.5.11-snapshot"

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

# Install java
ENV JAVA_HOME='/usr/lib/jvm/default-jvm'
# Limit JDK crypto policy by default to comply with local laws which may prohibit use of unlimited strength cryptography
RUN mkdir -p "${JAVA_HOME}" && \
    zulu8_amd64_url='https://cdn.azul.com/zulu/bin/zulu8.48.0.53-ca-jdk8.0.265-linux_x64.tar.gz' && \
    zulu8_armhf_url='https://cdn.azul.com/zulu-embedded/bin/zulu8.48.3.246-ca-jdk8.0.265-linux_aarch32hf.tar.gz' && \
    zulu8_arm64_url='https://cdn.azul.com/zulu-embedded/bin/zulu8.48.3.246-ca-jdk8.0.265-linux_aarch64.tar.gz' && \
    zulu11_amd64_url='https://cdn.azul.com/zulu/bin/zulu11.41.23-ca-jdk11.0.8-linux_x64.tar.gz' && \
    zulu11_armhf_url='https://cdn.azul.com/zulu-embedded/bin/zulu11.41.75-ca-jdk11.0.8-linux_aarch32hf.tar.gz' && \
    zulu11_arm64_url='https://cdn.azul.com/zulu-embedded/bin/zulu11.41.75-ca-jdk11.0.8-linux_aarch64.tar.gz' && \
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

# Install openHAB
# Set permissions for openHAB. Export TERM variable. See issue #30 for details!
RUN wget -nv -O /tmp/openhab.zip "https://ci.openhab.org/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-2.5.11-SNAPSHOT.zip" && \
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

# Expose volume with configuration and userdata dir
VOLUME ${OPENHAB_CONF} ${OPENHAB_USERDATA} ${OPENHAB_HOME}/addons

# Expose HTTP, HTTPS, Console and LSP ports
EXPOSE 8080 8443 8101 5007

# Set working directory and entrypoint
WORKDIR ${OPENHAB_HOME}
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Execute command
CMD ["gosu", "openhab", "tini", "-s", "./start.sh"]

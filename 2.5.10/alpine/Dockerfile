# openhab image
#
# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#
FROM alpine:3.12.0

# Set version variables
ENV \
    JAVA_VERSION="8" \
    OPENHAB_VERSION="2.5.10"

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

# Limit JDK crypto policy by default to comply with local laws which may prohibit use of unlimited strength cryptography
ENV JAVA_HOME='/usr/lib/jvm/default-jvm'
RUN if [ "${JAVA_VERSION}" = "8" ]; then \
        sed -i 's/^crypto.policy=unlimited/crypto.policy=limited/' "${JAVA_HOME}/jre/lib/security/java.security"; \
    elif [ "${JAVA_VERSION}" = "11" ]; then \
        sed -i 's/^crypto.policy=unlimited/crypto.policy=limited/' "${JAVA_HOME}/conf/security/java.security"; \
    fi

# Install openHAB
# Set permissions for openHAB. Export TERM variable. See issue #30 for details!
RUN wget -nv -O /tmp/openhab.zip "https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab%2F2.5.10%2Fopenhab-2.5.10.zip" && \
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
CMD ["su-exec", "openhab", "tini", "-s", "./start.sh"]

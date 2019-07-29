# openhab image
#
# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#
FROM multiarch/alpine:amd64-v3.9

# Set download urls
ENV \
    JAVA_URL="https://cdn.azul.com/zulu/bin/zulu8.33.0.1-jdk8.0.192-linux_x64.tar.gz" \
    OPENHAB_URL="https://bintray.com/artifact/download/openhab/bin/distribution-1.8.3-runtime.zip" \
    OPENHAB_VERSION="1.8.3"

# Set variables and locales
ENV \
    APPDIR="/openhab" \
    CRYPTO_POLICY="limited" \
    EXTRA_JAVA_OPTS="" \
    KARAF_EXEC="exec" \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    OPENHAB_HTTP_PORT="8080" \
    OPENHAB_HTTPS_PORT="8443"

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
RUN apk upgrade --no-cache && \
    apk add --no-cache \
        arping \
        bash \
        ca-certificates \
        curl \
        fontconfig \
        libpcap-dev \
        nss \
        shadow \
        su-exec \
        tini \
        ttf-dejavu \
        openjdk8 \
        unzip \
        wget \
        zip && \
    chmod u+s /usr/sbin/arping && \
    rm -rf /var/cache/apk/*

# Limit OpenJDK crypto policy by default to comply with local laws which may prohibit use of unlimited strength cryptography
ENV JAVA_HOME='/usr/lib/jvm/java-1.8-openjdk'
RUN rm -r "$JAVA_HOME/jre/lib/security/policy/unlimited" && \
    sed -i 's/^crypto.policy=unlimited/crypto.policy=limited/' "$JAVA_HOME/jre/lib/security/java.security"

# Install openHAB
RUN wget -nv -O /tmp/openhab.zip "${OPENHAB_URL}" && \
    unzip -q /tmp/openhab.zip -d "${APPDIR}" -x "*.bat" && \
    rm /tmp/openhab.zip && \
    cp -a "${APPDIR}/configurations" "${APPDIR}/configurations.dist" && \
    echo 'export TERM=${TERM:=dumb}' | tee -a ~/.bashrc

# Expose volume with configuration and userdata dir
VOLUME ${APPDIR}/configurations ${APPDIR}/addons

# Expose HTTP and HTTPS ports
EXPOSE 8080 8443

# Set working directory and entrypoint
WORKDIR ${APPDIR}
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Execute command
CMD ["su-exec", "openhab", "tini", "-s", "./start.sh"]

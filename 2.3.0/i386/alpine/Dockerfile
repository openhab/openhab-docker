# openhab image
#
# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#
FROM multiarch/alpine:i386-v3.7

# Set download urls
ENV 	    JAVA_URL="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_x64.tar.gz" 	    OPENHAB_URL="https://bintray.com/openhab/mvn/download_file?file_path=org%2Fopenhab%2Fdistro%2Fopenhab%2F2.3.0%2Fopenhab-2.3.0.zip" 	    OPENHAB_VERSION="2.3.0"

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

# Limit OpenJDK crypto policy by default to comply with local laws which may prohibit use of unlimited strength cryptography
ENV JAVA_HOME='/usr/lib/jvm/java-1.8-openjdk'
RUN rm -r "$JAVA_HOME/jre/lib/security/policy/unlimited" && \
    sed -i 's/^crypto.policy=unlimited/crypto.policy=limited/' "$JAVA_HOME/jre/lib/security/java.security"

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
RUN apk del build-dependencies && \
    rm -rf /var/cache/apk/*

# Expose HTTP, HTTPS, Console and LSP ports
EXPOSE 8080 8443 8101 5007

# Set working directory and entrypoint
WORKDIR ${APPDIR}
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Execute command
CMD ["su-exec", "openhab", "./start.sh"]

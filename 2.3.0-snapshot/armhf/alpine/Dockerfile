# openhab image
#
# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#
FROM multiarch/alpine:armhf-v3.7

# Set download urls
ENV 	    JAVA_URL="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_aarch32hf.tar.gz" 	    OPENHAB_URL="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-2.3.0-SNAPSHOT.zip" 	    OPENHAB_VERSION="2.3.0-snapshot"

# Set variables and locales
ENV \
    APPDIR="/openhab" \
    EXTRA_JAVA_OPTS="" \
    OPENHAB_HTTP_PORT="8080" \
    OPENHAB_HTTPS_PORT="8443" \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

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
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    ca-certificates \
    fontconfig \
    ttf-dejavu \
    libpcap-dev \
    unzip \
    dpkg \
    gnupg \
    wget \
    bash \
    shadow \
    openjdk8 \
    zip \
    su-exec && \
    rm -rf /var/cache/apk/*

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

# Set working directory, expose and entrypoint
WORKDIR ${APPDIR}
EXPOSE 8080 8443 5555
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Execute command
CMD ["su-exec", "openhab", "./start.sh"]

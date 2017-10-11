# openhab image
#
# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#

FROM multiarch/alpine:arm64-latest-stable

MAINTAINER openHAB <info@openhabfoundation.org>

# Set download urls
ENV JAVA_URL="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_aarch32hf.tar.gz"
ENV OPENHAB_URL="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-2.2.0-SNAPSHOT.zip"
ENV OPENHAB_VERSION="2.2.0-snapshot"

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

  # Install java
RUN apk add openjdk8

  # Install su-exec
RUN apk add su-exec

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

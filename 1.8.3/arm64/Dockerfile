# openhab image
#
# ------------------------------------------------------------------------------
#               NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
#                       PLEASE DO NOT EDIT IT DIRECTLY.
# ------------------------------------------------------------------------------
#

FROM multiarch/debian-debootstrap:arm64-jessie

# Set download urls
ENV OPENHAB_URL="https://bintray.com/artifact/download/openhab/bin/distribution-1.8.3-runtime.zip"
ENV JAVA_URL="https://www.azul.com/downloads/zulu/zdk-8-ga-linux_aarch32hf.tar.gz"

# Set variables
ENV \
    APPDIR="/openhab" \
    EXTRA_JAVA_OPTS="" \
    JAVA_HOME='/usr/lib/java-8' \
    OPENHAB_HTTP_PORT="8080" \
    OPENHAB_HTTPS_PORT="8443" \
    USER_ID="9001"

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
    org.label-schema.vcs-url="https://github.com/openhab/openhab-docker.git"

# Install basepackages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      ca-certificates \
      unzip \
      wget \
      && rm -rf /var/lib/apt/lists/*

# Install java
RUN wget -nv -O /tmp/java.tar.gz ${JAVA_URL} &&\
    mkdir ${JAVA_HOME} && \
    tar -xvf /tmp/java.tar.gz --strip-components=1 -C ${JAVA_HOME}

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 10
# GPIO Group for RPI access
RUN adduser -u $USER_ID --disabled-password --gecos '' --home ${APPDIR} openhab &&\
    groupadd -g 14 uucp2 &&\
    groupadd -g 16 dialout2 &&\
    groupadd -g 18 dialout3 &&\
    groupadd -g 32 uucp3 &&\
    groupadd -g 997 gpio &&\
    adduser openhab dialout &&\
    adduser openhab uucp &&\
    adduser openhab uucp2 &&\
    adduser openhab dialout2 &&\
    adduser openhab dialout3 &&\
    adduser openhab uucp3 &&\
    adduser openhab gpio

# Install openhab
# Set permissions for openhab. Export TERM variable. See issue #30 for details!
RUN wget -nv -O /tmp/openhab.zip ${OPENHAB_URL} &&\
    unzip -q /tmp/openhab.zip -d ${APPDIR} &&\
    rm /tmp/openhab.zip &&\
    chown -R openhab:openhab ${APPDIR} && \
    echo "export TERM=dumb" | tee -a ~/.bashrc

# Expose volume with configuration and userdata dir
WORKDIR ${APPDIR}
VOLUME ${APPDIR}/configurations ${APPDIR}/addons
EXPOSE 8080 8443 5555
USER openhab
CMD ["./start.sh"]


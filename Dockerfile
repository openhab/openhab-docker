# openhab image 
FROM multiarch/debian-debootstrap:amd64-jessie  # arch=amd64
#FROM multiarch/debian-debootstrap:armhf-jessie  # arch=armhf
#FROM multiarch/debian-debootstrap:arm64-jessie  # arch=arm64
ARG ARCH=amd64

ARG DOWNLOAD_URL="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-2.0.0-SNAPSHOT.zip"
ENV APPDIR="/openhab" OPENHAB_HTTP_PORT='8080' OPENHAB_HTTPS_PORT='8443' EXTRA_JAVA_OPTS=''

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

# Install Basepackages & OpenJDK8
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
      unzip \
      wget \
    && rm -rf /var/lib/apt/lists/*

# Install gosu
ENV GOSU_VERSION 1.10
RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# Install Oracle Java
RUN \
  echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
  echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  apt-get update && \
  apt-get install --no-install-recommends -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 10
# GPIO Group for RPI access
RUN adduser --disabled-password --gecos '' --home ${APPDIR} openhab &&\
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

WORKDIR ${APPDIR}

RUN \
    wget -nv -O /tmp/openhab.zip ${DOWNLOAD_URL} &&\
    unzip -q /tmp/openhab.zip -d ${APPDIR} &&\
    rm /tmp/openhab.zip

RUN mkdir -p ${APPDIR}/userdata/logs && touch ${APPDIR}/userdata/logs/openhab.log

# Copy directories for host volumes
RUN cp -a /openhab/userdata /openhab/userdata.dist && \
    cp -a /openhab/conf /openhab/conf.dist
COPY files/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

# Set permissions for openhab. Export TERM variable. See issue #30 for details!
RUN chown -R openhab:openhab ${APPDIR} && \
    echo "export TERM=dumb" | tee -a ~/.bashrc

# Expose volume with configuration and userdata dir
VOLUME ${APPDIR}/conf ${APPDIR}/userdata ${APPDIR}/addons
EXPOSE 8080 8443 5555
CMD ["server"]

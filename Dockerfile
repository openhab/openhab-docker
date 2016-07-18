# openhab image 
FROM multiarch/ubuntu-debootstrap:amd64-wily
#FROM multiarch/ubuntu-debootstrap:armhf-wily   # arch=armhf
#FROM multiarch/ubuntu-debootstrap:arm64-wily   # arch=arm64
ARG ARCH=amd64

ARG DOWNLOAD_URL="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab-online/target/openhab-online-2.0.0-SNAPSHOT.zip"
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

# Install Basepackages
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
      software-properties-common \
      sudo \
      unzip \
      wget \
    && rm -rf /var/lib/apt/lists/*

# Install Oracle Java
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install --no-install-recommends -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Add openhab user & handle possible device groups for different host systems
# Container base image puts dialout on group id 20, uucp on id 10
RUN adduser --disabled-password --gecos '' --home ${APPDIR} openhab &&\
    adduser openhab sudo &&\
    groupadd -g 14 uucp2 &&\
    groupadd -g 16 dialout2 &&\
    groupadd -g 18 dialout3 &&\
    groupadd -g 32 uucp3 &&\
    adduser openhab dialout &&\
    adduser openhab uucp &&\
    adduser openhab uucp2 &&\
    adduser openhab dialout2 &&\
    adduser openhab dialout3 &&\
    adduser openhab uucp3 &&\
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/openhab

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

RUN chown -R openhab:openhab ${APPDIR}

USER openhab
# Expose volume with configuration and userdata dir
VOLUME ${APPDIR}/conf ${APPDIR}/userdata ${APPDIR}/addons
EXPOSE 8080 8443 5555
CMD ["server"]

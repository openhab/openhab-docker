FROM debian:12-slim

ARG BUILD_DATE
ARG VCS_REF
ARG JAVA_VERSION
ARG OPENHAB_VERSION

ENV \
    CRYPTO_POLICY="limited" \
    EXTRA_JAVA_OPTS="" \
    EXTRA_SHELL_OPTS="" \
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
    OPENHAB_RUNTIME="/openhab/runtime" \
    OPENHAB_USERDATA="/openhab/userdata" \
    USER_ID="9001"

# Basic build-time metadata as defined at https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.licenses="EPL-2.0" \
    org.opencontainers.image.title="openHAB" \
    org.opencontainers.image.vendor="openHAB Foundation e.V." \
    org.opencontainers.image.version=$OPENHAB_VERSION \
    org.opencontainers.image.description="An open source, technology agnostic home automation platform" \
    org.opencontainers.image.url="https://www.openhab.org/" \
    org.opencontainers.image.documentation="https://www.openhab.org/docs/installation/docker.html" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.source="https://github.com/openhab/openhab-docker.git" \
    org.opencontainers.image.authors="openHAB <info@openhabfoundation.org>"

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install basepackages. Versions are "pinned" by using a pinned base image.
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get upgrade --yes && \
    openjdk_package="openjdk-${JAVA_VERSION}-jre-headless" && \
    apt-get install --no-install-recommends -y --dry-run "$openjdk_package" >/dev/null || openjdk_package="temurin-${JAVA_VERSION}-jre" && \
    if [ $(echo "$openjdk_package" | grep -E '^temurin-.+$') ]; then \
        DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y wget ca-certificates && \
        wget -nv -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /usr/share/keyrings/adoptium.asc && \
        echo "deb [signed-by=/usr/share/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
        apt-get update; \
    fi && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        arping \
        ca-certificates \
        curl \
        fontconfig \
        gosu \
        iputils-ping \
        libcap2-bin \
        locales \
        locales-all \
        netbase \
        "$openjdk_package" \
        procps \
        tini \
        unzip \
        vim-tiny \
        wget \
        zip && \
    c_rehash && \
    chmod u+s /usr/sbin/arping && \
    ln -s -f /bin/true /usr/bin/chfn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Limit JDK crypto policy by default to comply with local laws which may prohibit use of unlimited strength cryptography
RUN JAVA_HOME=$(find /usr/lib/jvm -mindepth 1 -maxdepth 1 -type d) && \
    sed -i 's/^crypto.policy=unlimited/crypto.policy=limited/' "${JAVA_HOME}/conf/security/java.security"

# Install openHAB
# Set permissions for openHAB. Export TERM variable. See issue #30 for details!
# Single quotes are used on purpose, so $TERM is expanded when running the container.
# hadolint ignore=SC2016
RUN version="$(echo $OPENHAB_VERSION | sed 's/snapshot/SNAPSHOT/g')" && \
    if [ $(echo $version | grep -E '^.+\.(M|RC).+$') ]; then url="https://openhab.jfrog.io/openhab/libs-milestone-local/org/openhab/distro/openhab/${version}/openhab-${version}.zip"; \
    elif [ $(echo $version | grep -E '^5\..+-SNAPSHOT$') ]; then url="https://ci.openhab.org/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab/target/openhab-${version}.zip"; \
    else url="https://openhab.jfrog.io/openhab/libs-release/org/openhab/distro/openhab/${version}/openhab-${version}.zip"; fi && \
    wget -nv -O /tmp/openhab.zip "$url" && \
    unzip -q /tmp/openhab.zip -d "${OPENHAB_HOME}" -x "*.bat" "*.ps1" "*.psm1" && \
    rm /tmp/openhab.zip && \
    mkdir -p "${OPENHAB_LOGDIR}" && \
    touch "${OPENHAB_LOGDIR}/openhab.log" && \
    mkdir -p "${OPENHAB_HOME}/dist" && \
    cp -a "${OPENHAB_CONF}" "${OPENHAB_USERDATA}" "${OPENHAB_HOME}/dist" && \
    echo 'export TERM=${TERM:=dumb}' | tee -a ~/.bashrc
COPY update ${OPENHAB_HOME}/runtime/bin/update
RUN chmod +x ${OPENHAB_HOME}/runtime/bin/update

# Add openhab-cli script from openhab-linuxpkg repo
RUN wget -nv -O /usr/bin/openhab-cli "https://raw.githubusercontent.com/openhab/openhab-linuxpkg/refs/heads/main/resources/usr/bin/openhab-cli" && \
    chmod +x /usr/bin/openhab-cli && \
    ln -s /usr/bin/vim.tiny /usr/bin/vim

# Expose volume with configuration and userdata dir
VOLUME ${OPENHAB_CONF} ${OPENHAB_USERDATA} ${OPENHAB_HOME}/addons

# Expose HTTP, HTTPS, Console and LSP ports
EXPOSE 8080 8443 8101 5007

# Set healthcheck
HEALTHCHECK --interval=5m --timeout=5s --retries=3 CMD curl -f http://localhost:${OPENHAB_HTTP_PORT}/ || exit 1

# Set working directory and entrypoint
WORKDIR ${OPENHAB_HOME}
COPY entrypoint /entrypoint
RUN chmod +x /entrypoint
ENTRYPOINT ["/entrypoint"]

# Execute command
CMD ["gosu", "openhab", "tini", "-s", "./start.sh"]

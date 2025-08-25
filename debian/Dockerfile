# Build su-exec used in the Docker image
ARG BASE_IMAGE=debian:13-slim
# hadolint ignore=DL3006
FROM ${BASE_IMAGE} AS su-exec-builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y ca-certificates curl gcc libc-dev && \
    curl -fsS -o "su-exec.c" "https://raw.githubusercontent.com/ncopa/su-exec/4c3bb42b093f14da70d8ab924b487ccfbb1397af/su-exec.c" && \
    echo "d6c40440609a23483f12eb6295b5191e94baf08298a856bab6e15b10c3b82891 su-exec.c" | sha256sum -c - && \
    gcc -Wall "su-exec.c" -o "su-exec"

# Build the openHAB Docker image
ARG BASE_IMAGE=debian:13-slim
# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

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

# Copy su-exec from the builder
COPY --from=su-exec-builder /su-exec /sbin/su-exec

# Install basepackages. Versions are "pinned" by using a pinned base image.
# hadolint ignore=DL3008,DL3015,SC2143
RUN apt-get update && \
    apt-get upgrade --yes && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        adduser \
        arping \
        ca-certificates \
        curl \
        fontconfig \
        iputils-ping \
        libcap2-bin \
        locales \
        locales-all \
        netbase \
        procps \
        tini \
        unzip \
        wget \
        zip && \
    # Install OpenJDK or fallback to Temurin depending on package availability
    openjdk_package="openjdk-${JAVA_VERSION}-jre-headless" && \
    apt-get install -y --dry-run "$openjdk_package" >/dev/null || openjdk_package="temurin-${JAVA_VERSION}-jre" && \
    if [ $(echo "$openjdk_package" | grep -E '^temurin-.+$') ]; then \
        wget -nv -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /usr/share/keyrings/adoptium.asc && \
        echo "deb [signed-by=/usr/share/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
        apt-get update; \
    fi && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$openjdk_package" && \
    # Install NodeJS only for openHAB >= 5
    if [ "$(echo $OPENHAB_VERSION | sed -E 's/^([0-9]+).*/\1/')" -ge 5 ]; then DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y nodejs; fi && \
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
CMD ["su-exec", "openhab", "tini", "-s", "./start.sh"]

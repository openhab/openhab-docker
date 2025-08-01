# openHAB Docker Containers

![openHAB logo](https://github.com/openhab/openhab-docker/raw/main/openhab.png)

[![Build Status](https://ci.openhab.org/job/openHAB-Docker/badge/icon)](https://ci.openhab.org/job/openHAB-Docker/)
[![EPL-2.0](https://img.shields.io/badge/license-EPL%202-green.svg)](https://opensource.org/licenses/EPL-2.0)
[![Docker Version](https://img.shields.io/badge/version-5.0.0-blue)](https://hub.docker.com/repository/docker/openhab/openhab/tags?name=5.0.0)
[![Docker Stars](https://img.shields.io/docker/stars/openhab/openhab.svg?cacheSeconds=2592000)](https://hub.docker.com/r/openhab/openhab/)
[![Docker Pulls](https://img.shields.io/docker/pulls/openhab/openhab.svg?cacheSeconds=2592000)](https://hub.docker.com/r/openhab/openhab/)
[![GitHub Issues](https://img.shields.io/github/issues/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/issues)
[![GitHub Stars](https://img.shields.io/github/stars/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/network)
[![CodeFactor](https://www.codefactor.io/repository/github/openhab/openhab-docker/badge)](https://www.codefactor.io/repository/github/openhab/openhab-docker)
[![Gitter Chat](https://badges.gitter.im/openhab/openhab-docker.svg)](https://gitter.im/openhab/openhab-docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Table of Contents

* [openHAB Docker Containers](#openhab-docker-containers)
  * [Introduction](#introduction)
  * [Image variants](#image-variants)
  * [Usage](#usage)
     * [Starting with Docker named volumes (for beginners)](#starting-with-docker-named-volumes-for-beginners)
        * [Running from command line](#running-from-command-line)
        * [Running from compose-file.yml](#running-from-compose-fileyml)
     * [Running openHAB with libpcap support](#running-openhab-with-libpcap-support)
     * [Running on Windows and macOS](#running-on-windows-and-macos)
     * [Starting with Docker mounting a host directory (for advanced user)](#starting-with-docker-mounting-a-host-directory-for-advanced-user)
     * [Automating Docker setup using ansible (for advanced user)](#automating-docker-setup-using-ansible-for-advanced-user)
     * [Accessing the console](#accessing-the-console)
     * [Startup modes](#startup-modes)
  * [Environment variables](#environment-variables)
     * [User and group identifiers](#user-and-group-identifiers)
     * [Java cryptographic strength policy](#java-cryptographic-strength-policy)
  * [Parameters](#parameters)
     * [Passing devices with symlinks](#passing-devices-with-symlinks)
  * [Executing shell scripts before openHAB is started](#executing-shell-scripts-before-openhab-is-started)
  * [Upgrading](#upgrading)
  * [Common problems](#common-problems)
  * [Building the images](#building-the-images)
  * [Contributing](#contributing)

## Introduction

Repository for building Docker containers for [openHAB](https://openhab.org) (Home Automation Server).
Comments, suggestions and contributions are welcome!

## Image variants

The openHAB Docker images are available in the [openhab/openhab](https://hub.docker.com/r/openhab/openhab/) repository on Docker Hub.

* For specific versions use:
  - `openhab/openhab:<version>`
  - `openhab/openhab:<version>-<distribution>`

* For the latest stable release use:
  - `openhab/openhab`
  - `openhab/openhab:latest`
  - `openhab/openhab:latest-<distribution>`

* For the latest release that has a milestone or stable maturity use:
  - `openhab/openhab:milestone`
  - `openhab/openhab:milestone-<distribution>`

* For the latest snapshot release use:
  - `openhab/openhab:snapshot`
  - `openhab/openhab:snapshot-<distribution>`

**Versions:**

* **Stable:** Thoroughly tested semi-annual official releases of openHAB. Use the stable version for your production environment if you do not need the latest enhancements and prefer a robust system.
  * `5.0.0` ([Release notes](https://github.com/openhab/openhab-distro/releases/tag/5.0.0))
  * `4.3.6` ([Release notes](https://github.com/openhab/openhab-distro/releases/tag/4.3.6))
* **Snapshot:** Usually 1 or 2 days old and include the latest code. Use these for testing out very recent changes using the latest code. Be aware that some snapshots might be unstable so use these in production at your own risk!
  * `5.1.0-snapshot`

**Distributions:**

* `debian` for Debian 12 "bookworm" (default when not specified in tag) ([Dockerfile](https://github.com/openhab/openhab-docker/blob/main/debian/Dockerfile))
* `alpine` for Alpine 3.22 ([Dockerfile](https://github.com/openhab/openhab-docker/blob/main/alpine/Dockerfile))

The Alpine images are substantially smaller than the Debian images but may be less compatible because OpenJDK is used (see [Prerequisites](https://www.openhab.org/docs/installation/#prerequisites) for known disadvantages).
Older container images may use older versions of the Debian and Alpine base images.

If you are unsure about what your needs are, you probably want to use `openhab/openhab:5.0.0`.

**Platforms:**

The following Docker platforms are supported (automatically determined):

* `linux/amd64`
* `linux/arm64`
* `linux/arm/v7` (Debian openHAB 4 (or older), Alpine openHAB 2 (or older))

## Usage

**Important:** To be able to use UPnP for discovery the container needs to be started with `--net=host`.

**Important:** In the container openHAB runs with user "openhab" (id 9001) by default. See user configuration section below!

The following will run openHAB in demo mode on the host machine:

`docker run --name openhab --net=host openhab/openhab:5.0.0`

_**NOTE:** Although this is the simplest method to getting openHAB up and running, but it is not the preferred method.
To properly run the container, please specify a **host volume** for the directories._

### Starting with Docker named volumes (for beginners)

The following configuration uses Docker named data volumes.
These volumes will survive, if you delete or upgrade your container.
It is a good starting point for beginners.
The volumes are created in the Docker volume directory.
You can use `docker inspect openhab` to locate the directories (e.g. /var/lib/docker/volumes) on your host system.
For more information visit [Manage data in containers](https://docs.docker.com/engine/tutorials/dockervolumes/).

#### Running from command line

```shell
docker run \
  --name openhab \
  --net=host \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  -v openhab_addons:/openhab/addons \
  -v openhab_conf:/openhab/conf \
  -v openhab_userdata:/openhab/userdata \
  -e "CRYPTO_POLICY=unlimited" \
  -e "EXTRA_JAVA_OPTS=-Duser.timezone=Europe/Berlin" \
  -d \
  --restart=always \
  openhab/openhab:5.0.0
```

#### Running from compose-file.yml

Create the following `docker-compose.yml` for use of local directories and start the container with `docker compose up -d`

```yaml
services:
  openhab:
    image: "openhab/openhab:5.0.0"
    restart: always
    network_mode: host
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "./openhab_addons:/openhab/addons"
      - "./openhab_conf:/openhab/conf"
      - "./openhab_userdata:/openhab/userdata"
    environment:
      CRYPTO_POLICY: "unlimited"
      EXTRA_JAVA_OPTS: "-Duser.timezone=Europe/Berlin"
      OPENHAB_HTTP_PORT: "8080"
      OPENHAB_HTTPS_PORT: "8443"
```

Create the following `docker-compose.yml` for use of Docker volumes and start the container with `docker compose up -d`

```yml
services:
  openhab:
    image: "openhab/openhab:5.0.0"
    restart: always
    network_mode: host
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "openhab_addons:/openhab/addons"
      - "openhab_conf:/openhab/conf"
      - "openhab_userdata:/openhab/userdata"
    environment:
      CRYPTO_POLICY: "unlimited"
      EXTRA_JAVA_OPTS: "-Duser.timezone=Europe/Berlin"
      OPENHAB_HTTP_PORT: "8080"
      OPENHAB_HTTPS_PORT: "8443"

volumes:
  openhab_addons:
    driver: local
  openhab_conf:
    driver: local
  openhab_userdata:
    driver: local
```

### Running openHAB with libpcap support

You can run all openHAB images with libpcap support by configuring additional capabilities.
This allows for using the *Amazon Dash Button Binding* in the Docker container.
Create the following `docker-compose.yml` and start the container with `docker compose up -d`

```yaml
services:
  openhab:
    container_name: openhab
    image: "openhab/openhab:5.0.0"
    restart: always
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "./openhab_addons:/openhab/addons"
      - "./openhab_conf:/openhab/conf"
      - "./openhab_userdata:/openhab/userdata"
```

### Running on Windows and macOS

The `host` networking driver only works on Linux hosts, and is not supported by Docker on Windows and macOS.
On Windows and macOS ports should be exposed by adding port options to commands (`-p 8080`) or by adding a ports section to `docker-compose.yml`.

```yaml
services:
  openhab:
    image: "openhab/openhab:5.0.0"
    restart: always
    ports:
      - "8080:8080"
      - "8443:8443"
    volumes:
      - "./openhab_addons:/openhab/addons"
      - "./openhab_conf:/openhab/conf"
      - "./openhab_userdata:/openhab/userdata"
    environment:
      CRYPTO_POLICY: "unlimited"
      EXTRA_JAVA_OPTS: "-Duser.timezone=Europe/Berlin"
      OPENHAB_HTTP_PORT: "8080"
      OPENHAB_HTTPS_PORT: "8443"
```

### Starting with Docker mounting a host directory (for advanced user)

You can mount a local host directory to store your configuration files.
If you followed the beginners guide, you do not need to read this section.
The following `run` command will create the folders and copy the initial configuration files for you.

```shell
docker run \
  --name openhab \
  --net=host \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  -v /opt/openhab/addons:/openhab/addons \
  -v /opt/openhab/conf:/openhab/conf \
  -v /opt/openhab/userdata:/openhab/userdata \
  -e "CRYPTO_POLICY=unlimited" \
  -e "EXTRA_JAVA_OPTS=-Duser.timezone=Europe/Berlin" \
  openhab/openhab:5.0.0
```

### Automating Docker setup using Ansible (for advanced user)

Here is an example playbook in case you control your environment with Ansible.
You can test it by running `ansible-playbook -i mycontainerhost, -t openhab run-containers.yml`.
The `:Z` at the end of volume lines is for SELinux systems.
If run elsewhere, replace it with ro.

```yaml
- name: ensure containers are running
  hosts: all
  tasks:

  - name: ensure openhab is up
    tags: openhab
    docker_container:
      name: openhab
      image: openhab/openhab:5.0.0
      state: started
      detach: yes
      ports:
        - 8080:8080
        - 8101:8101
        - 5007:5007
      volumes:
        - "/etc/localtime:/etc/localtime:ro"
        - "/etc/timezone:/etc/timezone:ro"
        - "/opt/openhab/addons:/openhab/addons:Z"
        - "/opt/openhab/conf:/openhab/conf:Z"
        - "/opt/openhab/userdata:/openhab/userdata:Z"
      keep_volumes: yes
      hostname: openhab.localnet
      memory: 512m
      pull: true
      restart_policy: unless-stopped
      env:
        CRYPTO_POLICY="unlimited"
        EXTRA_JAVA_OPTS="-Duser.timezone=Europe/Berlin"
```

### Accessing the console

You can connect to a console of an already running openHAB container with the following command:

`docker exec -it openhab /openhab/runtime/bin/client`

The default password for the login is: `habopen`

### Startup modes

#### Server mode

The container starts openHAB in server mode when no TTY is provided, example:

`docker run --detach --name openhab openhab/openhab:5.0.0`

When the container runs in server mode you can also add a console logger so it prints logging to stdout so you can check the logging of a container named "openhab" with:

`docker logs openhab`

To use a console logger with openHAB 3 (or newer), edit `userdata/etc/log4j2.xml` and add the following appender to the "Root logger" and "openhab.event" logger configurations: `<AppenderRef ref="STDOUT"/>`

To use a console logger with openHAB 2, edit `userdata/etc/org.ops4j.pax.logging.cfg` and then:

* Update the appenderRefs line to: `log4j2.rootLogger.appenderRefs = out, osgi, console`
* Add the following line: `log4j2.rootLogger.appenderRef.console.ref = STDOUT`

#### Regular mode

When a TTY is provided openHAB is started with an interactive console, e.g.: 

`docker run -it openhab/openhab:5.0.0`

#### Debug mode

The debug mode is started with the command:

`docker run -it openhab/openhab:5.0.0 ./start_debug.sh`

## Environment variables

* `CRYPTO_POLICY`=limited
* `EXTRA_JAVA_OPTS`=""
* `EXTRA_SHELL_OPTS`=""
* `LC_ALL`=en_US.UTF-8
* `LANG`=en_US.UTF-8
* `LANGUAGE`=en_US.UTF-8
* `OPENHAB_HTTP_PORT`=8080
* `OPENHAB_HTTPS_PORT`=8443
* `USER_ID`=9001
* `GROUP_ID`=9001

### User and group identifiers

The group ID will default to the same value as the user ID.
By default the openHAB user in the container is running with:

* `uid=9001(openhab) gid=9001(openhab) groups=9001(openhab)`

Make sure that either

* You create the same user with the same uid and gid on your Docker host system

```shell
groupadd -g 9001 openhab
useradd -u 9001 -g openhab -r -s /sbin/nologin openhab
usermod -a -G openhab myownuser
```

* Or run the Docker container with your own user AND pass the uid and gid to openHAB with environment variables

```shell
docker run \
(...)
-e USER_ID=<myownuserid> \
-e GROUP_ID=<myowngroupid> \
(...)
```

You can obtain your user and group ID by executing the `id --user` and `id --group` commands.

### Java cryptographic strength policy

Due to local laws and export restrictions the containers use Java with a limited cryptographic strength policy.
Some openHAB functionality may depend on unlimited strength which can be enabled by configuring the environment variable `CRYPTO_POLICY`=unlimited

Before enabling this make sure this is allowed by local laws and you agree with the applicable license and terms (see [OpenJDK (Cryptographic Cautions)](https://openjdk.java.net/groups/security)).

The following functionality depends on the unlimited cryptographic strength policy:

* air-Q Binding
* KM200 Binding
* Linky Binding
* Loxone Binding
* MQTT Binding
* openHAB Marketplace

## Parameters

* `-it` - starts openHAB with an interactive console (since openHAB 2.0.0)
* `-p 8080` - the HTTP port of the web interface
* `-p 8443` - the HTTPS port of the web interface
* `-p 8101` - the SSH port of the [Console](https://www.openhab.org/docs/administration/console.html) (since openHAB 2.0.0)
* `-p 5007` - the LSP port for [validating rules](https://github.com/openhab/openhab-vscode#validating-the-rules) (since openHAB 2.2.0)
* `-v /openhab/addons` - custom openHAB addons
* `-v /openhab/conf` - openHAB configs
* `-v /openhab/userdata` - openHAB userdata directory
* `--device=/dev/ttyUSB0` - attach your devices like RFXCOM or Z-Wave Sticks to the container

### Passing devices with symlinks

On Linux, if you pass a device with a symlink or any non standard name (e.g. /dev/ttyZWave), some addons require the device name to follow the Linux serial port naming rules (e.g. "ttyACM0", "ttyUSB0" or "ttyUSB-9999") or will otherwise fail to discover the device.

This can be achieved by mapping the devices to a compliant name like this:

```shell
docker run \
(...)
--device=/dev/ttyZWave:/dev/ttyACM0
--device=/dev/ttyZigbee:/dev/ttyACM1
(...)
```

More information about serial ports and symlinks can be found [here](https://www.openhab.org/docs/administration/serial.html).

## Executing shell scripts before openHAB is started

It is sometimes useful to run shell scripts after the "userdata" directory is created, but before Karaf itself is launched.
One such case is creating SSH host keys, and allowing access to the system from the outside via SSH.
Exemplary scripts can be found in the [contrib/cont-init.d](https://github.com/openhab/openhab-docker/tree/main/contrib/cont-init.d) directory

To use this, create a directory called

```shell
/etc/cont-init.d
```

and add a volume mount to your startup:

```shell
  ...
  -v /etc/cont-init.d:/etc/cont-init.d \
  ...
```

and put your scripts into that directory.
This can be done by either using a volume mount (see the examples above) or creating your own images which inherit from the official ones.

## Upgrading

Upgrading openHAB requires changes to the user mapped in userdata folder.
The container will perform these steps automatically when it detects that the `userdata/etc/version.properties` is different from the version in `dist/userdata/etc/version.properties` in the Docker image.

The steps performed are:
* Create a `userdata/backup` folder if one does not exist.
* Create a full backup of userdata as a dated tar file saved to `userdata/backup`. The `userdata/backup` folder is excluded from this backup.
* Show update notes and warnings.
* Execute update pre/post commands.
* Copy userdata system files from `dist/userdata/etc` to `userdata/etc`.
* Update KAR files in `addons`.
* Delete the contents of `userdata/cache` and `userdata/tmp`.

The steps performed are the same as those performed by running the upgrade script that comes with OH, except the backup is performed differently and the latest openHAB runtime is not downloaded.
All messages shown during the update are also logged to `userdata/logs/update.log`.

## Common problems

### Error: KARAF_ETC is not valid

This error message indicates that the data in the volumes is not properly initialized.
The error is usually the result of a permissions issue or already putting files into volumes without the volumes having been initialized by the container first.
When mounting directories into the container, check that these directories exist, are completely empty and are owned by the same `USER_ID` and `GROUP_ID` as configured in the container ENV variables.

### Missing some preinstalled package

Docker containers are kept as small as possible intentionally to decrease download times and the number of potential vulnerabilities for everyone.
If you want additional packages installed, create your own container based on this container.
Another option is to install the package by [executing a shell script before openHAB is started](#executing-shell-scripts-before-openhab-is-started).

### No logging after "Launching the openHAB runtime..."

By default this will always be the last logged message.
A console logger can be [configured](#server-mode) for more detailed logging.

### OpenJDK Client VM warning: No monotonic clock was available

This error message may occur when running a recent openHAB container image on a Docker host with an outdated version of libseccomp2.
The issue can be fixed by upgrading libseccomp2 on your Docker host to a more recent version.
For more details see this [community thread](https://community.openhab.org/t/128865).

### OpenMediaVault

The default filesystem mount flags of OpenMediaVault contain the `noexec` flag which interferes with the serial library used by openHAB.
To be able to use serial devices with openHAB, make sure the `userdata` volume mounted by the container is not backed by a filesystem having the `noexec` flag.
See the [OMV documentation](https://openmediavault.readthedocs.io/en/6.x/various/fs_env_vars.html) on how to remove the `noexec` flag from an existing filesystem.

### Portainer

The default values of ENV variables are always stored by Portainer (see [portainer/portainer#2952](https://github.com/portainer/portainer/issues/2952)).
This causes issues such as endless restart loops when upgrading the container with Portainer.
To resolve this issue when upgrading openHAB, first remove all default (non-overridden) ENV variables before starting the new container.

### SELinux

When using the container on a Linux distribution with SELinux enabled (CentOS/Fedora/RHEL), add the `:z` or `:Z` option to volumes to give the container write permissions.
For more information on this see the [Docker documentation](https://docs.docker.com/storage/bind-mounts/#configure-the-selinux-label).

## Building the images

Checkout the GitHub repository, change to a directory containing a Dockerfile (e.g. `/debian`) and then run these commands to build and run a Docker image for your current platform:

```shell
$ docker build --build-arg JAVA_VERSION=21 --build-arg OPENHAB_VERSION=5.0.0 --tag openhab/openhab .
$ docker run openhab/openhab
```

To be able to build the same image for other platforms (e.g. arm/v7, arm64 on amd64) Docker CE with BuildKit support can be used.

First configure QEMU binary formats and a builder using:

```shell
$ docker run --privileged --rm tonistiigi/binfmt:qemu-v9.2.2 --install all
$ docker buildx create --name builder --use
```

Change to a directory containing a Dockerfile (e.g. `/debian`) and then use the following command to build an ARM64 image:

```shell
$ docker buildx build --build-arg JAVA_VERSION=21 --build-arg OPENHAB_VERSION=5.0.0 --platform linux/arm64 --tag openhab/openhab --load .
```

The `build` script in the root of the repository helps to simplify building the openHAB images with BuildKit.
It can be used to build the images of multiple openHAB versions and correctly tag and push them to a Docker registry.
Execute `./build -h` for usage instructions and examples.

## Contributing

[Contribution guidelines](https://github.com/openhab/openhab-docker/blob/main/CONTRIBUTING.md)

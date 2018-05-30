# openHAB Docker Containers
![](images/openhab.png)

[![Build state](https://travis-ci.org/openhab/openhab-docker.svg?branch=master)](https://travis-ci.org/openhab/openhab-docker) [![](https://images.microbadger.com/badges/image/openhab/openhab:2.3.0-amd64-debian.svg)](https://microbadger.com/images/openhab/openhab:2.3.0-amd64-debian "Get your own image badge on microbadger.com") [![Docker Label](https://images.microbadger.com/badges/version/openhab/openhab:2.3.0-amd64-debian.svg)](https://microbadger.com/#/images/openhab/openhab:2.3.0-amd64-debian) [![Docker Stars](https://img.shields.io/docker/stars/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Docker Pulls](https://img.shields.io/docker/pulls/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Join the chat at https://gitter.im/openhab/openhab-docker](https://badges.gitter.im/openhab/openhab-docker.svg)](https://gitter.im/openhab/openhab-docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![GitHub issues](https://img.shields.io/github/issues/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/issues) [![Issue Stats](http://www.issuestats.com/github/openhab/openhab-docker/badge/issue?style=flat)](http://www.issuestats.com/github/openhab/openhab-docker) [![GitHub forks](https://img.shields.io/github/forks/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/network) [![Issue Stats](http://www.issuestats.com/github/openhab/openhab-docker/badge/pr?style=flat)](http://www.issuestats.com/github/openhab/openhab-docker) [![GitHub stars](https://img.shields.io/github/stars/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/stargazers)

Table of Contents
=================

   * [openHAB Docker Containers](#openhab-docker-containers)
      * [Introduction](#introduction)
      * [Image Variants](#image-variants)
      * [Usage](#usage)
         * [Starting with Docker named volumes (for beginners)](#starting-with-docker-named-volumes-for-beginners)
            * [Running from command line](#running-from-command-line)
            * [Running from compose-file.yml](#running-from-compose-fileyml)
            * [Running openHAB with libpcap support](#running-openhab-with-libpcap-support)
         * [Starting with Docker mounting a host directory (for advanced user)](#starting-with-docker-mounting-a-host-directory-for-advanced-user)
         * [Accessing the console](#accessing-the-console)
      * [Environment variables](#environment-variables)
      * [Parameters](#parameters)
      * [Building the image](#building-the-image)
      * [Contributing](#contributing)
      * [License](#license)

## Introduction

Repository for building Docker containers for [openHAB](http://openhab.org) (Home Automation Server). Comments, suggestions and contributions are welcome!

## Docker Image

[![dockeri.co](http://dockeri.co/image/openhab/openhab)](https://hub.docker.com/r/openhab/openhab/)

## Image Variants

``openhab/openhab:<version>-<architecture>-<distributions>``

**Version**

* [``1.8.3`` Stable openHAB 1.8 version](https://github.com/openhab/openhab-docker/blob/master/1.8.3/amd64/debian/Dockerfile)
* [``2.0.0`` Stable openHAB 2.0 version](https://github.com/openhab/openhab-docker/blob/master/2.0.0/amd64/debian/Dockerfile)
* [``2.1.0`` Stable openHAB 2.1 version](https://github.com/openhab/openhab-docker/blob/master/2.1.0/amd64/debian/Dockerfile)
* [``2.2.0`` Stable openHAB 2.2 version](https://github.com/openhab/openhab-docker/blob/master/2.2.0/amd64/debian/Dockerfile)
* [``2.3.0`` Stable openHAB 2.3 version](https://github.com/openhab/openhab-docker/blob/master/2.3.0/amd64/debian/Dockerfile)
* [``2.4.0-snapshot`` Experimental openHAB 2.4 SNAPSHOT version](https://github.com/openhab/openhab-docker/blob/master/2.4.0-snapshot/amd64/debian/Dockerfile)

**Architecture:**

* ``amd64`` for most desktop computer (e.g. x64, x86-64, x86_64)
* ``armhf`` for ARMv7 devices 32 Bit (e.g. most RaspberryPi 1/2/3)
* ``arm64`` for ARMv8 devices 64 Bit (not RaspberryPi 3)

**Distributions:**

* ``debian`` for debian stretch
* ``alpine`` for alpine 3.7

The alpine images are substantially smaller than the debian images but may be less compatible because OpenJDK is used (see [Prerequisites](https://www.openhab.org/docs/installation/#prerequisites) for known disadvantages).

If you are unsure about what your needs are, you probably want to use
 ``openhab/openhab:2.3.0-amd64-debian``.

Prebuilt Docker Images can be found here: [Docker Images](https://hub.docker.com/r/openhab/openhab)

## Usage

**Important:** To be able to use UPnP for discovery the container needs to be started with ``--net=host``.

**Important:** In the container openHAB runs with user "openhab" (id 9001) by default. See user configuration section below!

The following will run openHAB in demo mode on the host machine:
```
docker run -it --name openhab --net=host openhab/openhab:2.3.0-amd64-debian
```
_**NOTE:** Although this is the simplest method to getting openHAB up and running, but it is not the preferred method. To properly run the container, please specify a **host volume** for the directories._

### Starting with Docker named volumes (for beginners)

Following configuration uses Docker named data volumes. These volumes will survive, if you delete or upgrade your container. It is a good starting point for beginners. The volumes are created in the Docker volume directory. You can use ``docker inspect openhab`` to locate the directories (e.g. /var/lib/docker/volumes) on your host system. For more information visit  [Manage data in containers](https://docs.docker.com/engine/tutorials/dockervolumes/):

#### Running from command line

```SHELL
docker run \
        --name openhab \
        --net=host \
        --tty \
        -v /etc/localtime:/etc/localtime:ro \
        -v /etc/timezone:/etc/timezone:ro \
        -v openhab_addons:/openhab/addons \
        -v openhab_conf:/openhab/conf \
        -v openhab_userdata:/openhab/userdata \
        -d \
        --restart=always \
        openhab/openhab:2.3.0-amd64-debian
```

#### Running from compose-file.yml

Create the following ``docker-compose.yml`` and start the container with ``docker-compose up -d``

```YAML
version: '2.2'

services:
  openhab:
    image: "openhab/openhab:2.3.0-amd64-debian"
    restart: always
    network_mode: host
    tty: true
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "openhab_addons:/openhab/addons"
      - "openhab_conf:/openhab/conf"
      - "openhab_userdata:/openhab/userdata"
    environment:
      OPENHAB_HTTP_PORT: "8080"
      OPENHAB_HTTPS_PORT: "8443"
```

#### Running openHAB with libpcap support

You can run all openHAB images with libpcap support. This enables you to use the *Amazon Dashbutton Binding* in the Docker container. For that feature to work correctly, you need to run the image as **root user**. Create the following ``docker-compose.yml`` and start the container with ``docker-compose up -d``

```YAML
version: '2.2'

services:
  openhab:
    container_name: openhab
    image: "openhab/openhab:2.3.0-amd64-debian"
    restart: always
    tty: true
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "openhab_conf:/openhab/conf"
      - "openhab_userdata:/openhab/userdata"
      - "openhab_addons:/openhab/addons"
    # The command node is very important. It overrides
    # the "gosu openhab ./start.sh" command from Dockerfile and runs as root!
    command: "./start.sh"
```
*If you could provide a method to run libpcap support in user mode please open a pull request.*

### Starting with Docker mounting a host directory (for advanced user)

You can mount a local host directory to store your configuration files. If you followed the beginners guide, you do not need to read this section. The following ``run`` command will create the folders and copy the initial configuration files for you.

```SHELL
docker run \
  --name openhab \
  --net=host \
  --tty \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  -v /opt/openhab/addons:/openhab/addons \
  -v /opt/openhab/conf:/openhab/conf \
  -v /opt/openhab/userdata:/openhab/userdata \
  openhab/openhab:2.3.0-amd64-debian
```

### Accessing the console

You can connect to a console of an already running openHAB container with following command:
* ``docker ps``  - lists all your currently running container
* ``docker exec -it openhab /openhab/runtime/bin/client`` - connect to openHAB container by name
* ``docker exec -it c4ad98f24423 /openhab/runtime/bin/client`` - connect to openHAB container by id
* ``docker attach openhab`` - attach to openHAB container by name, input only works when starting the container with `-i`  (or `stdin_open: true` with docker compose)

The default password for the login is ``habopen``.

**Debug Mode**

You can run a new container with the command ``docker run -it openhab/openhab:2.3.0-amd64-debian ./start_debug.sh`` to get into the debug shell.

## Environment variables

*  `EXTRA_JAVA_OPTS`=""
*  `LC_ALL`=en_US.UTF-8
*  `LANG`=en_US.UTF-8
*  `LANGUAGE`=en_US.UTF-8
*  `OPENHAB_HTTP_PORT`=8080
*  `OPENHAB_HTTPS_PORT`=8443
*  `USER_ID`=9001
*  `GROUP_ID`=9001
*  `CRYPTO_POLICY`=limited

### User and group identifiers

Group id will default to the same value as the user id. By default the openHAB user in the container is running with:

* `uid=9001(openhab) gid=9001(openhab) groups=9001(openhab)`

Make sure that either

* You create the same user with the same uid and gid on your docker host system
```
groupadd -g 9001 openhab
useradd -u 9001 -g openhab -r -s /sbin/nologin openhab
usermod -a -G openhab myownuser
```

* Or run the docker container with your own user AND passing the userid to openHAB through env
```
docker run \
(...)
--user <myownuserid> \
-e USER_ID=<myownuserid>
```

### Java cryptographic strength policy

Due to local laws and export restrictions the containers use Java with a limited cryptographic strength policy. Some openHAB functionality (e.g. KM200 binding) may depend on unlimited strength which can be enabled by configuring the environment variable `CRYPTO_POLICY`=unlimited 

Before enabling this make sure this is allowed by local laws and you agree with the applicable license and terms:

* debian: [Zulu (Cryptography Extension Kit)](https://www.azul.com/products/zulu-and-zulu-enterprise/zulu-cryptography-extension-kit)
* alpine: [OpenJDK (Cryptographic Cautions)](http://openjdk.java.net/groups/security)

## Parameters

* `-p 8080` - the HTTP port of the web interface
* `-p 8443` - the HTTPS port of the web interface
* `-p 8101` - the SSH port of the [Console](https://www.openhab.org/docs/administration/console.html) (since openHAB 2.0.0)
* `-p 5007` - the LSP port for [validating rules](https://github.com/openhab/openhab-vscode#validating-the-rules) (since openHAB 2.2.0)
* `-v /openhab/addons` - custom openHAB addons
* `-v /openhab/conf` - openHAB configs
* `-v /openhab/userdata` - openHAB userdata directory
* `--device=/dev/ttyUSB0` - attach your devices like RFXCOM or Z-Wave Sticks to the container

## Upgrading

Upgrading OH requires changes to the user mapped in userdata folder. The container will perform these steps automatically when it detects that the `userdata/etc/version.properties` is different from the version in `userdata.dist/etc/version.properties` in the Docker image. The steps performed are:

* Create a `userdata/backup` folder if one does not exist.
* Create a full backup of userdata as a dated tar file saved to `userdata/backup`. The `userdata/backup` folder is excluded from this backup.
* Copy over the relevant files from `userdata.dist/etc` to `userdata/etc`.
* Delete the contents of `userdata/cache` and `userdata/tmp`.

The steps performed are the same as those performed by running the upgrade script that comes with OH, except the backup is performed differently and the latest openHAB runtime is not downloaded.

## Building the image

Checkout the github repository and then run these commands:
```
$ docker build -t openhab/openhab .
$ docker run -it openhab/openhab server
```

## Contributing

[Contribution guidelines](https://github.com/openhab/openhab-docker/blob/master/CONTRIBUTING.md)

## License

When not explicitly set, files are placed under [![Eclipse license](https://img.shields.io/badge/license-Eclipse-blue.svg)](https://raw.githubusercontent.com/openhab/openhab-docker/master/LICENSE).

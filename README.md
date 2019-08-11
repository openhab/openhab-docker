# openHAB Docker Containers

![](images/openhab.png)

[![Build state](https://travis-ci.org/openhab/openhab-docker.svg?branch=master)](https://travis-ci.org/openhab/openhab-docker) [![](https://images.microbadger.com/badges/image/openhab/openhab:2.4.0.svg)](https://microbadger.com/images/openhab/openhab:2.4.0 "Get your own image badge on microbadger.com") [![Docker Label](https://images.microbadger.com/badges/version/openhab/openhab:2.4.0.svg)](https://microbadger.com/#/images/openhab/openhab:2.4.0) [![Docker Stars](https://img.shields.io/docker/stars/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Docker Pulls](https://img.shields.io/docker/pulls/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Join the chat at https://gitter.im/openhab/openhab-docker](https://badges.gitter.im/openhab/openhab-docker.svg)](https://gitter.im/openhab/openhab-docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![GitHub issues](https://img.shields.io/github/issues/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/issues) [![GitHub forks](https://img.shields.io/github/forks/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/network) [![GitHub stars](https://img.shields.io/github/stars/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/stargazers)

Table of Contents
=================

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
      * [Upgrading](#upgrading)
      * [Building the images](#building-the-images)
      * [Executing shell scripts before openHAB is started](#executing-shell-scripts-before-openhab-is-started)
      * [Contributing](#contributing)
      * [License](#license)

## Introduction

Repository for building Docker containers for [openHAB](http://openhab.org) (Home Automation Server).
Comments, suggestions and contributions are welcome!

## Docker Image

[![dockeri.co](http://dockeri.co/image/openhab/openhab)](https://hub.docker.com/r/openhab/openhab/)

## Image variants

* For specific versions use:
  - `openhab/openhab:<version>`
  - `openhab/openhab:<version>-<distribution>`
  - `openhab/openhab:<version>-<architecture>-<distribution>`

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

* `1.8.3` Stable openHAB 1.8.3 version ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/1.8.3/debian/Dockerfile-amd64))
* `2.0.0` Stable openHAB 2.0.0 version ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/2.0.0/debian/Dockerfile-amd64))
* `2.1.0` Stable openHAB 2.1.0 version ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/2.1.0/debian/Dockerfile-amd64))
* `2.2.0` Stable openHAB 2.2.0 version ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/2.2.0/debian/Dockerfile-amd64))
* `2.3.0` Stable openHAB 2.3.0 version ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/2.3.0/debian/Dockerfile-amd64))
* `2.4.0` Stable openHAB 2.4.0 version ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/2.4.0/debian/Dockerfile-amd64))
* `2.5.0.M1` Experimental openHAB 2.5.0.M1 Milestone version ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/2.5.0.M1/debian/Dockerfile-amd64))
* `2.5.0.M2` Experimental openHAB 2.5.0.M2 Milestone version ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/2.5.0.M2/debian/Dockerfile-amd64))
* `2.5.0-snapshot` Experimental openHAB 2.5.0 SNAPSHOT version ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/2.5.0-snapshot/debian/Dockerfile-amd64))

**Architectures:**

* `amd64` for most desktop computers (e.g. x64, x86-64, x86_64)
* `armhf` for ARMv7 devices 32 Bit (e.g. most Raspberry Pi 1/2/3/4)
* `arm64` for ARMv8 devices 64 Bit (not Raspberry Pi 3/4)

Newer Docker versions (1.10.0+) have multi-architecture support which allows for omitting the architecture from the tag.

**Distributions:**

* `debian` for Debian 10 "buster" (default when not specified in tag)
* `alpine` for Alpine 3.10

The Alpine images are substantially smaller than the Debian images but may be less compatible because OpenJDK is used (see [Prerequisites](https://www.openhab.org/docs/installation/#prerequisites) for known disadvantages).

If you are unsure about what your needs are, you probably want to use `openhab/openhab:2.4.0`.

Prebuilt Docker Images can be found here: [Docker Images](https://hub.docker.com/r/openhab/openhab)

## Usage

**Important:** To be able to use UPnP for discovery the container needs to be started with `--net=host`.

**Important:** In the container openHAB runs with user "openhab" (id 9001) by default. See user configuration section below!

The following will run openHAB in demo mode on the host machine:

`docker run --name openhab --net=host openhab/openhab:2.4.0`

_**NOTE:** Although this is the simplest method to getting openHAB up and running, but it is not the preferred method.
To properly run the container, please specify a **host volume** for the directories._

### Starting with Docker named volumes (for beginners)

Following configuration uses Docker named data volumes. These volumes will survive, if you delete or upgrade your container.
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
        -e "EXTRA_JAVA_OPTS=-Duser.timezone=Europe/Berlin" \
        -d \
        --restart=always \
        openhab/openhab:2.4.0
```

#### Running from compose-file.yml

Create the following `docker-compose.yml` for use of local directories and start the container with `docker-compose up -d`

```yaml
version: '2.2'

services:
  openhab:
    image: "openhab/openhab:2.4.0"
    restart: always
    network_mode: host
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "./openhab_addons:/openhab/addons"
      - "./openhab_conf:/openhab/conf"
      - "./openhab_userdata:/openhab/userdata"
    environment:
      OPENHAB_HTTP_PORT: "8080"
      OPENHAB_HTTPS_PORT: "8443"
      EXTRA_JAVA_OPTS: "-Duser.timezone=Europe/Berlin"
```

Create the following `docker-compose.yml` for use of Docker volumes and start the container with `docker-compose up -d`

```yml
version: '2.2'

services:
  openhab:
    image: "openhab/openhab:2.4.0"
    restart: always
    network_mode: host
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "openhab_addons:/openhab/addons"
      - "openhab_conf:/openhab/conf"
      - "openhab_userdata:/openhab/userdata"
    environment:
      OPENHAB_HTTP_PORT: "8080"
      OPENHAB_HTTPS_PORT: "8443"
      EXTRA_JAVA_OPTS: "-Duser.timezone=Europe/Berlin"

volumes:
  openhab_addons:
    driver: local
  openhab_conf:
    driver: local
  openhab_userdata:
    driver: local
```

#### Running openHAB with libpcap support

You can run all openHAB images with libpcap support. This enables you to use the *Amazon Dashbutton Binding* in the Docker container.
For that feature to work correctly, you need to run the image as **root user**.
Create the following `docker-compose.yml` and start the container with `docker-compose up -d`

```yaml
version: '2.2'

services:
  openhab:
    container_name: openhab
    image: "openhab/openhab:2.4.0"
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
    # The command node is very important. It overrides
    # the "gosu openhab tini -s ./start.sh" command from Dockerfile and runs as root!
    command: "tini -s ./start.sh server"
```

*If you could provide a method to run libpcap support in user mode please open a pull request.*

#### Running on Windows and macOS

The `host` networking driver only works on Linux hosts, and is not supported by Docker on Windows and macOS.
On Windows and macOS ports should be exposed by adding port options to commands (`-p 8080`) or by adding a ports section to `docker-compose.yml`.

```yaml
version: '2.2'

services:
  openhab:
    image: "openhab/openhab:2.4.0"
    restart: always
    ports:
      - "8080:8080"
      - "8443:8443"
    volumes:
      - "./openhab_addons:/openhab/addons"
      - "./openhab_conf:/openhab/conf"
      - "./openhab_userdata:/openhab/userdata"
    environment:
      OPENHAB_HTTP_PORT: "8080"
      OPENHAB_HTTPS_PORT: "8443"
      EXTRA_JAVA_OPTS: "-Duser.timezone=Europe/Berlin"
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
  -e "EXTRA_JAVA_OPTS=-Duser.timezone=Europe/Berlin" \
  openhab/openhab:2.4.0
```

### Automating Docker setup using Ansible (for advanced user)

Here is an example playbook in case you control your environment with Ansible. You can test it by running `ansible-playbook -i mycontainerhost, -t openhab run-containers.yml`. The `:Z` at the end of volume lines is for SELinux systems. If run elsewhere, replace it with ro.

```yaml
- name: ensure containers are running
  hosts: all
  tasks:

  - name: ensure openhab is up
    tags: openhab
    docker_container:
      name: openhab
      image: openhab/openhab:2.4.0
      state: started
      detach: yes
      interactive: yes
      tty: yes
      ports:
        - 8080:8080
        - 8101:8101
        - 5007:5007
      volumes:
        - /etc/localtime:/etc/localtime:ro
        - /etc/timezone:/etc/timezone:ro
        - /opt/openhab/addons:/openhab/addons:Z
        - /opt/openhab/conf:/openhab/conf:Z
        - /opt/openhab/userdata:/openhab/userdata:Z
      keep_volumes: yes
      hostname: openhab.localnet
      memory: 512m
      pull: true
      restart_policy: unless-stopped
      env:
        EXTRA_JAVA_OPTS="-Duser.timezone=Europe/Berlin"
```

### Accessing the console

You can connect to a console of an already running openHAB container with following command:

* `docker ps` - lists all your currently running container
* `docker exec -it openhab /openhab/runtime/bin/client` - connect to openHAB container by name
* `docker exec -it openhab /openhab/runtime/bin/client -p habopen` - connect to openHAB container by name and use `habopen` as password (**not recommended** because this makes the password visible in the command history and process list)
* `docker exec -it c4ad98f24423 /openhab/runtime/bin/client` - connect to openHAB container by id
* `docker attach openhab` - attach to openHAB container by name, input only works when starting the container with `-it` (or `stdin_open: true` and `tty: true` with Docker Compose)

The default password for the login is `habopen`.

### Startup modes

#### Server mode

The container starts openHAB in server mode when no TTY is provided, example:

`docker run --detach --name openhab openhab/openhab:2.4.0`

When the container runs in server mode you can also add a console logger so it prints logging to stdout so you can check the logging of a container named "openhab" with:

`docker logs openhab`

To add the console logger, edit `userdata/etc/org.ops4j.pax.logging.cfg` and then:

* Update the appenderRefs line to: `log4j2.rootLogger.appenderRefs = out, osgi, console`
* Add the following line: `log4j2.rootLogger.appenderRef.console.ref = STDOUT`

#### Regular mode

When a TTY is provided openHAB is started with an interactive console, e.g.: 

`docker run -it openhab/openhab:2.4.0`

#### Debug mode

The debug mode is started with the command:

`docker run -it openhab/openhab:2.4.0 ./start_debug.sh`

## Environment variables

* `EXTRA_JAVA_OPTS`=""
* `LC_ALL`=en_US.UTF-8
* `LANG`=en_US.UTF-8
* `LANGUAGE`=en_US.UTF-8
* `OPENHAB_HTTP_PORT`=8080
* `OPENHAB_HTTPS_PORT`=8443
* `USER_ID`=9001
* `GROUP_ID`=9001
* `CRYPTO_POLICY`=limited

### User and group identifiers

Group id will default to the same value as the user id. 
By default the openHAB user in the container is running with:

* `uid=9001(openhab) gid=9001(openhab) groups=9001(openhab)`

Make sure that either

* You create the same user with the same uid and gid on your Docker host system

```shell
groupadd -g 9001 openhab
useradd -u 9001 -g openhab -r -s /sbin/nologin openhab
usermod -a -G openhab myownuser
```

* Or run the Docker container with your own user AND passing the userid to openHAB through env

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

Before enabling this make sure this is allowed by local laws and you agree with the applicable license and terms:

* Debian: [Zulu (Cryptography Extension Kit)](https://www.azul.com/products/zulu-and-zulu-enterprise/zulu-cryptography-extension-kit)
* Alpine: [OpenJDK (Cryptographic Cautions)](http://openjdk.java.net/groups/security)

The following addons are known to depend on the unlimited cryptographic strength policy:

* Eclipse IoT Market
* KM200 binding
* MQTT binding

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

## Upgrading

Upgrading OH requires changes to the user mapped in userdata folder.
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

## Building the images

Checkout the GitHub repository, change to a directory containing Dockerfiles (e.g. `2.4.0/debian`) and then run these commands to build and run a amd64 image:

```shell
$ docker build -f Dockerfile-amd64 -t openhab/openhab .
$ docker run openhab/openhab
```

To be able to build images for other architectures (e.g. armhf/arm64 on amd64) QEMU User Emulation first needs to be registered with:

```shell
$ docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

## Executing shell scripts before openHAB is started

It is sometimes useful to run shell scripts after the "userdata" directory is created, but before karaf itself is launched.
One such case is creating SSH host keys, and allowing access to the system from the outside via SSH.
Exemplary scripts can be found in the [contrib](https://github.com/openhab/openhab-docker/tree/master/contrib) directory

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

### Show the contents of the running Docker image

[10-show-directories](https://github.com/openhab/openhab-docker/blob/master/contrib/cont-init.d/10-show-directories)

```shell
ls -l /openhab
ls -l /openhab/userdata
```

### Set a defined host key for the image

[20-set-host-key](https://github.com/openhab/openhab-docker/blob/master/contrib/cont-init.d/20-set-host-key)

```shell
cat > /openhab/userdata/etc/host.key <<EOF
-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQCrOe8O7r9uOjKu
... your key here ...
c2woMmUlKznoVPczYMncRJ3oBg==
-----END PRIVATE KEY-----
EOF
```

### Open access from external hosts

[20-open-ssh-server](https://github.com/openhab/openhab-docker/blob/master/contrib/cont-init.d/20-open-ssh-server)

```shell
sed -i \
    "s/\#org.apache.karaf.shell:sshHost\s*=.*/org.apache.karaf.shell:sshHost=0.0.0.0/g" \
    /openhab/conf/services/runtime.cfg
```

### Set a defined host key for the image

[20-add-allowed-ssh-keys](https://github.com/openhab/openhab-docker/blob/master/contrib/cont-init.d/20-add-allowed-ssh-keys)

```shell
cat > /openhab/userdata/etc/keys.properties <<EOF
openhab=A...your-ssh-public-key-here...B,_g_:admingroup

_g_\:admingroup = group,admin,manager,viewer

EOF
```

### Configure credentials for openHAB cloud

[40-openhabcloud](https://github.com/openhab/openhab-docker/blob/master/contrib/cont-init.d/40-openhabcloud)

```shell
if [ ! -z ${OHC_UUID} ]
then
    mkdir -p /openhab/userdata
    echo ${OHC_UUID} > /openhab/userdata/uuid
fi

if [ ! -z ${OHC_SECRET} ]
then
    mkdir -p /openhab/userdata/openhabcloud
    echo ${OHC_SECRET} > /openhab/userdata/openhabcloud/secret
fi
```


### Give pcap permissions to the Java process

[50-setpcap-on-java](https://github.com/openhab/openhab-docker/blob/master/contrib/cont-init.d/50-setpcap-on-java)

```shell
setcap 'cap_net_bind_service=+ep' /usr/lib/java-8/bin/java
```

## Contributing

[Contribution guidelines](https://github.com/openhab/openhab-docker/blob/master/CONTRIBUTING.md)

## License

When not explicitly set, files are placed under [![EPL-2.0 license](https://img.shields.io/badge/license-EPL--2.0-blue.svg)](https://raw.githubusercontent.com/openhab/openhab-docker/master/LICENSE)

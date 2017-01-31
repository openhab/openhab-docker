# openHAB2 Docker Containers
![](https://github.com/openhab/openhab-docker/raw/master/images/openhab.png)

[![Build state](https://travis-ci.org/openhab/openhab-docker.svg?branch=master)](https://travis-ci.org/openhab/openhab-docker) [![](https://images.microbadger.com/badges/image/openhab/openhab:2.0.0-amd64.svg)](https://microbadger.com/images/openhab/openhab:2.0.0-amd64 "Get your own image badge on microbadger.com") [![Docker Label](https://images.microbadger.com/badges/version/openhab/openhab:2.0.0-amd64.svg)](https://microbadger.com/#/images/openhab/openhab:2.0.0-amd64) [![Docker Stars](https://img.shields.io/docker/stars/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Docker Pulls](https://img.shields.io/docker/pulls/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Join the chat at https://gitter.im/openhab/openhab-docker](https://badges.gitter.im/openhab/openhab-docker.svg)](https://gitter.im/openhab/openhab-docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


Repository for building Docker containers for [openHAB](http://openhab.org) (Home Automation Server).

Comments, suggestions and contributions are welcome!


## Contributing

[![GitHub issues](https://img.shields.io/github/issues/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/issues) [![Issue Stats](http://www.issuestats.com/github/openhab/openhab-docker/badge/issue?style=flat)](http://www.issuestats.com/github/openhab/openhab-docker) [![GitHub forks](https://img.shields.io/github/forks/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/network) [![Issue Stats](http://www.issuestats.com/github/openhab/openhab-docker/badge/pr?style=flat)](http://www.issuestats.com/github/openhab/openhab-docker) [![GitHub stars](https://img.shields.io/github/stars/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/stargazers)

[Contribution guidelines](https://github.com/openhab/openhab-docker/blob/master/CONTRIBUTING.md)


## License

When not explicitly set, files are placed under [![Eclipse license](https://img.shields.io/badge/license-Eclipse-blue.svg)](https://raw.githubusercontent.com/openhab/openhab-docker/master/LICENSE).


## Image Variants

### ``openhab/openhab:<version>-<architecture>``

#### Version:

* [``2.0.0`` Stable openHAB version](https://github.com/openhab/openhab-docker/blob/master/2.0.0/amd64/Dockerfile)
* [``2.1.0-SNAPSHOT`` Experimental openHAB snapshot version](https://github.com/openhab/openhab-docker/blob/master/2.1.0-snapshot/amd64/Dockerfile)

#### Architecture:

* ``amd64`` for most desktop computer (e.g. x64, x86-64, x86_64)
* ``armhf`` for ARMv7 devices 32 Bit (e.g. most RaspberryPi 1/2/3)
* ``arm64`` for ARMv8 devices 64Bit (not RaspberryPi 3)

If you are unsure about what your needs are, you probably want to use ``openhab/openhab:2.0.0-amd64``.

Prebuilt Docker Images can be found here: [Docker Images](https://hub.docker.com/r/openhab/openhab)


## Usage

**Important** To be able to use UPnP for discovery the container needs to be started with ``--net=host``.

The following will run openHAB in demo mode on the host machine:
```
docker run -it --name openhab --net=host openhab/openhab:2.0.0-amd64
```
_**NOTE** Although this is the simplest method to getting openHAB up and running, but it is not the prefered method. To properly run the container, please specify a **host volume** for the directories._


### Starting using Docker named volumes (for beginners)

Following configuration uses Docker named data volumes. These volumes will survive, if you delete or upgrade your container. It is a good starting point for beginners. The volumes are created in the Docker volume directory. You can use ``docker inspect openhab`` to locate the directories (e.g. /var/lib/docker/volumes) on your host system. For more information visit  [Manage data in containers](https://docs.docker.com/engine/tutorials/dockervolumes/):

#### Running from command line
```SHELL
docker run \
        --name openhab \
        --net=host \
        -v /etc/localtime:/etc/localtime:ro \
        -v /etc/timezone:/etc/timezone:ro \
        -v openhab_addons:/openhab/addons \
        -v openhab_conf:/openhab/conf \
        -v openhab_userdata:/openhab/userdata \
        -d \
        --restart=always \
        openhab/openhab:2.0.0-amd64
```

#### Running from compose-file.yml

Create the following ``docker-compose.yml`` and start the container with ``docker-compose up -d``

```YAML
openhab:
  image: "openhab/openhab:2.0.0-amd64"
  restart: always
  net: host
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

### Mount a host directory as a data volume (for advanced user)

You can mount a local host directory to store your configuration files. If you followed the beginners guide, you do not need to read this section. When using mounted volumes Docker only mounts existing data into the openHAB container. If you have no configuration files in this folder, openHAB will not start. You can copy the initial configutration files from the openHab image to the mounted volume. First you need to create the host directories.

```SHELL
mkdir /opt/openhab/ && \
mkdir /opt/openhab/addons/ && \
mkdir /opt/openhab/conf/ && \
mkdir /opt/openhab/userdata/ && \
chown 9001.9001 /opt/openhab -R
```

By default the openHAB user runs as user id 9001. Next copy the initial configuration files from the openHAB image to your host folder:

```SHELL
docker run --rm \
  --user 9001
  -v /opt/openhab/addons:/openhab/addons \
  -v /opt/openhab/conf:/openhab/conf \
  -v /opt/openhab/userdata:/openhab/userdata \
  openhab/openhab:2.0.0-amd64 \
  sh -c 'cp -av /openhab/userdata.dist/* /openhab/userdata/ && \
  cp -av /openhab/conf.dist/* /openhab/conf/'
```

You should now be able to run the container with following command:

```SHELL
sudo docker run \
  --user 9001 \
  --name openhab \
  --net=host \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  -v /opt/openhab/addons:/openhab/addons \
  -v /opt/openhab/conf:/openhab/conf \
  -v /opt/openhab/userdata:/openhab/userdata \
  openhab/openhab:2.0.0-amd64
```

### Accessing the console

You can connect to a console of an already running openHAB container with following command:
* ``docker ps``  - lists all your currently running container
* ``docker exec -it openhab /openhab/runtime/bin/client`` - connect to openHAB container by name
* ``docker exec -it c4ad98f24423 /openhab/runtime/bin/client`` - connect to openHAB container by id

The default password for the login is ``habopen``.

**Debug Mode**

You can run a new container with the command ``docker run -it openhab/openhab:2.0.0-amd64 ./start_debug.sh`` to get into the debug shell.

### Environment variables

*  `OPENHAB_HTTP_PORT`=8080
*  `OPENHAB_HTTPS_PORT`=8443
*  `EXTRA_JAVA_OPTS`=""
*  `USER_ID`=9001

By default the openHAB user in the container is running with:

* `uid=9001(openhab) gid=9001(openhab) groups=9001(openhab)`

### Parameters

* `-p 8080` - the port of the webinterface
* `-v /openhab/addons` - custom openhab addons
* `-v /openhab/conf` - openhab configs
* `-v /openhab/userdata` - openhab userdata directory
* `--device=/dev/ttyUSB0` - attach your devices like RFXCOM or Z-Wave Sticks to the container

## Building the image

Checkout the github repository and then run these commands:
```
$ docker build -t openhab/openhab .
$ docker run -it openhab/openhab server
```

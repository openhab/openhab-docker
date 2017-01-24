# openHAB2 Docker Containers

[![Build state](https://travis-ci.org/openhab/openhab-docker.svg?branch=master)](https://travis-ci.org/openhab/openhab-docker) [![](https://images.microbadger.com/badges/image/openhab/openhab:amd64.svg)](https://microbadger.com/images/openhab/openhab:amd64 "Get your own image badge on microbadger.com") [![Docker Label](https://images.microbadger.com/badges/version/openhab/openhab:amd64.svg)](https://microbadger.com/#/images/openhab/openhab:amd64) [![Docker Stars](https://img.shields.io/docker/stars/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Docker Pulls](https://img.shields.io/docker/pulls/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Join the chat at https://gitter.im/openhab/openhab-docker](https://badges.gitter.im/openhab/openhab-docker.svg)](https://gitter.im/openhab/openhab-docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Repository for building docker containers for [openHAB](http://openhab.org) (Home Automation Server).

Comments, suggestions and contributions are welcome!


## Contributing

[![GitHub issues](https://img.shields.io/github/issues/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/issues) [![Issue Stats](http://www.issuestats.com/github/openhab/openhab-docker/badge/issue?style=flat)](http://www.issuestats.com/github/openhab/openhab-docker) [![GitHub forks](https://img.shields.io/github/forks/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/network) [![Issue Stats](http://www.issuestats.com/github/openhab/openhab-docker/badge/pr?style=flat)](http://www.issuestats.com/github/openhab/openhab-docker) [![GitHub stars](https://img.shields.io/github/stars/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/stargazers)

[Contribution guidelines](https://github.com/openhab/openhab-docker/blob/master/CONTRIBUTING.md)


## License

When not explicitly set, files are placed under [![Eclipse license](https://img.shields.io/badge/license-Eclipse-blue.svg)](https://raw.githubusercontent.com/openhab/openhab-docker/master/LICENSE).


## Image Variants

### ``openhab/openhab:<architecture>``

* ``amd64`` for most desktop computer (e.g. x64, x86-64, x86_64)
* ``armhf`` for ARMv7 devices 32 Bit (e.g. most RaspberryPi 1/2/3)
* ``arm64`` for ARMv8 devices 64Bit (not RaspberryPi 3)

If you are unsure about what your needs are, you probably want to use ``openhab/openhab:amd64``.


Prebuilt Docker Images can be found here: [Docker Images](https://hub.docker.com/r/openhab/openhab) ([Dockerfile](https://github.com/openhab/openhab-docker/blob/master/Dockerfile))

## Usage

**Important** To be able to use UPnP for discovery the container needs to be started with ``--net=host``.

The following will run openHAB in demo mode on the host machine:
```
docker run -it --name openhab --net=host openhab/openhab:amd64 server
```

**NOTE** Although this is the simplest method to getting openHAB up and running, but it is not the preferred method. To properly run the container, please specify a **host volume** for the ``conf`` and ``userdata`` directory:


```SHELL
docker run \
        --name openhab \
        --net=host \
        -v /etc/localtime:/etc/localtime:ro \
        -v /etc/timezone:/etc/timezone:ro \
        -v /opt/openhab/conf:/openhab/conf \
        -v /opt/openhab/userdata:/openhab/userdata \
        -d \
        --restart=always \
        openhab/openhab:amd64
```

or with ``docker-compose.yml`` and UPnP for discovery:

```YAML
openhab:
  image: "openhab/openhab:amd64"
  restart: always
  net: host
  volumes:
    - "/etc/localtime:/etc/localtime:ro"
    - "/etc/timezone:/etc/timezone:ro"
    - "/opt/openhab/userdata:/openhab/userdata"
    - "/opt/openhab/conf:/openhab/conf"
  environment:
    OPENHAB_HTTP_PORT: "8080"
    OPENHAB_HTTPS_PORT: "8443"
  command: server
```
Create and start the container with ``docker-compose up -d``

**Accessing the console**

You can connect to a console of an already running openhab container with following command:
* ``docker ps``  - lists all your currently running container
* ``docker exec -it openhab /openhab/runtime/bin/client`` - connect to given container by name
* ``docker exec -it c4ad98f24423 /openhab/runtime/bin/client`` - connect to given container by id

**Debug Mode**

You can run a new container with the command ``docker run -it openhab/openhab:<architecture> debug`` to get into the debug shell.

**Environment variables**

*  `OPENHAB_HTTP_PORT`=8080
*  `OPENHAB_HTTPS_PORT`=8443
*  `EXTRA_JAVA_OPTS`=""

**Parameters**

* `-p 8080` - the port of the webinterface
* `-v /openhab/conf` - openhab configs
* `-v /openhab/userdata` - openhab userdata directory
* `--device=/dev/ttyUSB0` - attach your devices like RFXCOM or Z-Wave Sticks to the container

## Building the image

Checkout the github repository and then run these commands:
```
$ docker build -t openhab/openhab .
$ docker run -it openhab/openhab server
```



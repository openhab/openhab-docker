# openHAB Docker Containers

[![Build state](https://travis-ci.org/openhab/openhab-docker.svg?branch=master)](https://travis-ci.org/openhab/openhab-docker) [![Docker Image Layers](https://imagelayers.io/badge/openhab/openhab:latest.svg)](https://imagelayers.io/?images=openhab/openhab:latest 'Get your own badge on imagelayers.io') [![Docker Label](https://images.microbadger.com/badges/version/openhab/openhab:amd64-offline.svg)](https://microbadger.com/#/images/openhab/openhab:amd64-offline) [![Docker Stars](https://img.shields.io/docker/stars/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Docker Pulls](https://img.shields.io/docker/pulls/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Join the chat at https://gitter.im/openhab/openhab-docker](https://badges.gitter.im/openhab/openhab-docker.svg)](https://gitter.im/openhab/openhab-docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Repository for building docker containers for [openHAB](http://openhab.org) (Home Automation Server).

Comments, suggestions and contributions are welcome!


## Contributing

[![GitHub issues](https://img.shields.io/github/issues/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/issues) [![Issue Stats](http://www.issuestats.com/github/openhab/openhab-docker/badge/issue?style=flat)](http://www.issuestats.com/github/openhab/openhab-docker) [![GitHub forks](https://img.shields.io/github/forks/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/network) [![Issue Stats](http://www.issuestats.com/github/openhab/openhab-docker/badge/pr?style=flat)](http://www.issuestats.com/github/openhab/openhab-docker) [![GitHub stars](https://img.shields.io/github/stars/openhab/openhab-docker.svg)](https://github.com/openhab/openhab-docker/stargazers)

[Contribution guidelines](https://github.com/openhab/openhab-docker/blob/master/CONTRIBUTING.md)


## License

When not explicitly set, files are placed under [![Eclipse license](https://img.shields.io/badge/license-Eclipse-blue.svg)](https://raw.githubusercontent.com/openhab/openhab-docker/master/LICENSE).


## Image Variants

### ``openhab/openhab:<architecture>-<[on|off]line>``

* ``amd64``: ``online``, ``offline``
* ``armhf``: ``online``, ``offline``
* ``arm64``: ``online``, ``offline``

If you are unsure about what your needs are, you probably want to use ``openhab/openhab:amd64-online``.

prebuilt Docker Images can be found here: [Docker Images](https://hub.docker.com/r/openhab/openhab)

## Usage

**Important** To be able to use UPnP for discovery the container needs to be started with ``--net=host``.

The following will run openHAB in demo mode on the host machine:
```
docker run -it --name openhab --net=host openhab/openhab:amd64-online server
```

**NOTE** Although this is the simplest method to getting openHAB up and running, but it is not the preferred method. To properly run the container, please specify a **host volume** for the ``conf`` and ``userdata`` directory:


```
docker run \
        --name openhab \
        --net=host \
        -v /etc/localtime:/etc/localtime:ro \
        -v /etc/timezone:/etc/timezone:ro \
        -v /opt/openhab/conf:/openhab/conf \
        -v /opt/openhab/userdata:/openhab/userdata \
        -d \
        --restart=always \
        openhab/openhab:amd64-online
```

or with ``docker-compose.yml``
```
---
openhab:
  image: 'openhab/openhab:amd64-online'
  restart: always
  ports:
    - "8080:8080"
    - "8443:8443"
    - "5555:5555"
  net: "host"
  volumes:
    - '/etc/localtime:/etc/localtime:ro'
    - '/etc/timezone:/etc/timezone:ro'
    - '/opt/openhab/userdata:/openhab/userdata'
    - '/opt/openhab/conf:/openhab/conf'
  command: "server"
```
then start with ``docker-compose up -d``

**Accessing the console**
``docker exec -it openhab /openhab/runtime/bin/client``

**Debug Mode**

You can start the container with the command ``docker run -it openhab/openhab debug`` to get into the debug shell.

**Environment variables**
*  `OPENHAB_HTTP_PORT`=8080
*  `OPENHAB_HTTPS_PORT`=8443
*  `EXTRA_JAVA_OPTS`

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

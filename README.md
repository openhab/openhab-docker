# openHAB Docker Containers

[![Build state](https://travis-ci.org/openhab/openhab-docker.svg?branch=master)](https://travis-ci.org/openhab/openhab-docker) [![](https://imagelayers.io/badge/openhab/openhab:latest.svg)](https://imagelayers.io/?images=openhab/openhab:latest 'Get your own badge on imagelayers.io') [![Docker Stars](https://img.shields.io/docker/stars/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Docker Pulls](https://img.shields.io/docker/pulls/openhab/openhab.svg?maxAge=2592000)](https://hub.docker.com/r/openhab/openhab/) [![Join the chat at https://gitter.im/openhab/openhab-docker](https://badges.gitter.im/openhab/openhab-docker.svg)](https://gitter.im/openhab/openhab-docker?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Repository for building docker containers for [openHAB](http://openhab.org) (Home Automation Server).

Comments, suggestions and contributions are welcome!

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
``docker exec -it openhab console``

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

## Contributing

[Contribution guidelines](https://github.com/openhab/openhab-docker/blob/master/CONTRIBUTING.md)

## License

When not explicitly set, files are placed under [EPL](https://github.com/openhab/openhab-docker/blob/master/LICENSE) license.

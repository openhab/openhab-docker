#!/bin/sh -ex

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

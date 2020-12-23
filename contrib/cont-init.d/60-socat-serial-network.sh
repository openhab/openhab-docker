#!/bin/bash
# https://community.openhab.org/t/cant-use-forwarded-socat-serial-port-in-lgtvserial-binding-ioexception/97965
# https://community.openhab.org/t/forwarding-of-serial-and-usb-ports-over-the-network-to-openhab/46597
apt-get update
apt-get install socat -y -q

# use while loop to restart socat on connection end
while /bin/true; do
    socat -d -d -s -lf /openhab/userdata/logs/socat.log pty,link=/dev/ttyNET0,raw,user=openhab,group=openhab,mode=777 tcp:192.168.188.17:20108,forever,intervall=10
    sleep 1
done &> /dev/null &

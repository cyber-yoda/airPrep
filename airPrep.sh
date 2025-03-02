#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    echo -e ' [-] Run with sudo. '
    exit
fi

rfkill NetworkManger stop

airmon-ng check kill 

read -p "Interface to use for monitoring: " interface
airmon-ng start $interface

dhclient $interface
#!/bin/bash

# check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit
fi


if [ -z "${OS_COMBATIBLE:-}" ] || [ "${OS_COMBATIBLE:-}" ]; then
    # check running compatible system
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        OS_VER=$VERSION_ID
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        OS_VER=$(uname -r)
    fi

    case $OS in
    "Debian GNU/Linux")
        OS_COMBATIBLE=true
        ;;
    "Ubuntu")
        OS_COMBATIBLE=true
        ;;
    *)  OS_COMBATIBLE=false
        exit 1
        ;;
    esac
fi

if [ ! -f /usr/bin/dialog ] || [ ! -f /usr/bin/python3 ] || [ ! -f /usr/bin/pip3 ] || [ ! -f /usr/bin/dirmngr ]; then
    infoscreen "Installing" "packages needed for setup"
    hide_output apt-get -q -q update
    apt_get_quiet install dialog python3 python3-pip dirmngr || exit 1
    infoscreendone
fi
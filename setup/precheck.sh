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
    "CentOS Linux")
        OS_COMBATIBLE=true
        ;;
    *)
        echo "Unsupported OS $OS" | tee /dev/fd/3
        exit 1
        ;;
    esac
fi
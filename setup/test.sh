#!/bin/bash
set -euo pipefail

IFS=$'\n\t'

# Setting some path
declare -r DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ ! -d "$DIR/log" ] && mkdir "$DIR/log"
declare -r FILE_LOG="$( cd "$DIR/log" && pwd )/$$.log"
# Put all output to logfile
exec 3>&1 1>>${FILE_LOG} 2>&1

update_param() {
	# $1 required a file path
	# $2 required a search term
	# $3 required a string to replace
    if [ ! -n ${1:-} ]; then
        echo "update_param() requires the file path as the first argument"
        return 1;
    fi
    if [ ! -n ${2:-} ]; then
        echo "comment_param() requires the search term as the second argument"
        return 1;
    fi
    if [ ! -n ${3:-} ]; then
        echo "comment_param() requires a string value as the third argument"
        return 1;
    fi
	grep -q $2 $1 && sed -i "s/^#*\($2\).*/$3 $2/g" $1 || echo "$3 $2 #added by TirsvadCMS LinuxServerSetupScript" >> $1
}

PRIMARY_HOSTNAME='test.tirsvad-cms.dk'

hostnamectl set-hostname $PRIMARY_HOSTNAME
update_param "/etc/hosts" ${PRIMARY_HOSTNAME} "127.0.0.1"

apt-mark hold linux-image-4.9.0-8-amd64

apt-get -qq update
# apt-get -qq upgrade

apt-get -qq install ufw
# ufw logging off
ufw default deny incoming
ufw default allow outgoing
ufw allow SSH
ufw --force enable

apt-mark unhold linux-image-4.9.0-8-amd64
apt-get -qq upgrade
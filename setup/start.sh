#!/bin/bash
IFS=$'\n\t'

# Setting some path
declare -r DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare -r DIR_CONF="$( cd "$DIR/../conf" && pwd )"
declare -r FILE_TOOLS_NGINX_SETUP="$( cd "$DIR/../tools/nginxSetup" && pwd )/nginxSetup.sh"
[ ! -d "$DIR/../log" ] && mkdir "$DIR/../log"
declare -r FILE_LOG="$( cd "$DIR/../log" && pwd )/$$.log"
# Put all output to logfile
exec 3>&1 1>>${FILE_LOG} 2>&1

. $DIR_CONF/settings.sh
. $DIR/functions.sh
. $DIR/precheck.sh
. $DIR/system.sh
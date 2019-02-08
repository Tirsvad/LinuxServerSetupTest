#!/bin/bash
set -euo pipefail

############################################################
## screen output
############################################################
NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'
BROWN='\033[0;33m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
WHITE='\033[0;37m'

function hide_output {
    # This function hides the output of a command unless the command fails
	# and returns a non-zero exit code.

    # Get a temporary file.
    OUTPUT=$(tempfile)


    # Execute command, redirecting stderr/stdout to the temporary file.
    # Since we check the return code ourselves, disable 'set -e' temporarily.
    set +e
    $@ &> $OUTPUT
    E=$?
    set -e

    # If the command failed, show the output that was captured in the temporary file.
    if [ $E != 0 ]; then
        echo
        echo FAILED: $@
        echo -----------------------------------------
        cat $OUTPUT
        echo -----------------------------------------
        exit $E
    fi

	# Remove temporary file.
	rm -f $OUTPUT
}

function infoscreen {
	printf "%-.70s" $(printf "${BROWN}$1 ${BLUE}$2 : ......................................................................${NC}")
}

function infoscreendone {
	printf " ${GREEN}DONE${NC}\n"
}

function infoscreenfailed {
	printf " ${RED}FAILED${NC}\n"
}

############################################################
## Apt functions
############################################################
function apt_get_quiet {
	# Run apt-get in a totally non-interactive mode.
	DEBIAN_FRONTEND=noninteractive hide_output apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
}

############################################################
## System tools
############################################################
function get_default_hostname {
	# Guess the machine's hostname. It should be a fully qualified
	# domain name suitable for DNS. None of these calls may provide
	# the right value, but it's the best guess we can make.
	set -- $(hostname --fqdn      2>/dev/null ||
                 hostname --all-fqdns 2>/dev/null ||
                 hostname             2>/dev/null)
	printf '%s\n' "$1" # return this value
}

## Uncapitalize a string
function lower {
	# $1 required a string
    # return an uncapitalize string
    if [ ! -n ${1:-} ]; then
        echo "lower() requires the a string as the first argument"
        return 1;
    fi

	echo $1 | tr '[:upper:]' '[:lower:]'
}

function get_publicip_from_web_service {
    curl -$1 --fail --silent --max-time 15 icanhazip.com 2>/dev/null || /bin/true
}

function system_get_user_home {
	# $1 required a user name
    # return user hame path
	cat /etc/passwd | grep "^$1:" | cut --delimiter=":" -f6
}

## Delete domain in /etc/hosts
function hostname_delete {
	# $1 required a domain name
    if [ ! -n ${1:-} ]; then
        echo "hostname_delete() requires the domain name as the first argument"
        return 1;
    fi

    if [ -z "$1" ]; then
        local newhost=${1//./\\.}
        sed -i "/$newhost/d" /etc/hosts
    fi
}

############################################################
## Net tools
############################################################
function kill_prosses_port() {
    ## kill prosses that is listen to port number
    # $1 required a port number
    kill $(fuser -n tcp $1 2> /dev/null)
}

############################################################
## Param tools
############################################################
function update_param_boolean {
	# $1 required a file path
	# $2 required a search term
	# $3 required a boolean value
    if [ ! -n ${1:-} ]; then
        echo "update_param_boolean() requires the file path as the first argument"
        return 1;
    fi
    if [ ! -n ${2:-} ]; then
        echo "update_param_boolean() requires the search term as the second argument"
        return 1;
    fi
    if [ ! -n ${3:-} ]; then
        echo "update_param_boolean() requires the boolean value as the third argument"
        return 1;
    fi

	VALUE=`lower $3`
	case $3 in
		yes|no|on|off|true|false)
			grep -q $2 $1 && sed -i "s/^#*\($2\).*/\1 $3/" $1 || echo "$2 $3 #added by TirsvadCMS LinuxServerSetupScript" >> $1
			;;
		*)
			echo "I dont think this $3 is a boolean"
			return 1
			;;
	esac
}

function update_param {
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
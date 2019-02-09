#!/bin/bash

###################################################################################
# Privamy hostname.
###################################################################################
#PRIMARY_HOSTNAME="" # PRIMARY_HOSTNAME="www.examble.com"

###################################################################################
# Your hosts public IP adress.
###################################################################################
#PUBLIC_IP="192.168.0.0" # script will find this by it self
#PUBLIC_IPV6=""

###################################################################################
# The privilige user that is in sudoers
###################################################################################
#USER_ID=""
#USER_PASSWORD=""
USER_SHELL="/bin/bash"
#USER_SSHKEY=""
#USER_HOME=""

###################################################################################
# SSHD settings
###################################################################################
# SSHD_PERMITROOTLOGIN="no" # option yes|no
# SSHD_PASSWORDAUTH="no" # option yes|no

###################################################################################
# Software
###################################################################################
#SOFTWARE_INSTALL_NGINX="on" # option on|off
#SOFTWARE_INSTALL_AJENTI="on" # option on|off
#SOFTWARE_INSTALL_DB="on" # option on|off
    #SOFTWARE_INSTALL_POSTGRESQL="on" # option on|off
    #SOFTWARE_INSTALL_MYSQL="off" # option on|off

###################################################################################
# NGINX SETTINGS
###################################################################################
#NGINX_SITES_AVAILABE='/etc/nginx/sites-available/'
#NGINX_SITES_ENABLE='/etc/nginx/sites-enabled/'
NGINX_HTML_BASE_DIR='/var/html'
#NGINX_SITES_HOSTNAMES=('example.com' 'blog.example.com') # Only used for extra host names. Privamy hostname is by default set to be hosted by nginx.

###################################################################################
# Let's encrypt SETTINGS
###################################################################################
#LETSENCRYPT_EMAIL=''

###################################################################################
# WARNING hardcore settings
# Please don't uncomment this unless you know what it does
###################################################################################
#OS_COMBATIBLE=true # forcing setup

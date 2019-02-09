#!/bin/bash

. setup/sslcertificate.sh
. setup/nginx.sh

if [ -z "${NONINTERACTIVE:-}" ]; then
    . setup/questions.sh
fi

printf "\n\n"

if [[ ! -z "${PRIMARY_HOSTNAME:-}" ]]; then
    infoscreen "Setting" "hostname ${PRIMARY_HOSTNAME}"
    # First set the hostname in the configuration file, then activate the setting
    hostnamectl set-hostname $PRIMARY_HOSTNAME
    cp /etc/hosts /etc/hosts.backup
    update_param "/etc/hosts" ${PRIMARY_HOSTNAME} "127.0.0.1"
    infoscreendone
fi

infoscreen "Updating" "System and software"
hide_output apt-get update
apt_get_quiet upgrade
infoscreendone

infoscreen "Adding" "priviliged user ${USER_ID}"
set +e
id "${USER_ID}" >/dev/null 2>&1
USEREXIST=$?
set -e
if  [ ! $USEREXIST -eq 0  ]; then
    USER_ID=`lower $USER_ID`
    hide_output useradd --create-home -s "$USER_SHELL" "$USER_ID"
    echo "$USER_ID:$USER_PASSWORD" | chpasswd
    hide_output which sudo
    if [ ! $? -eq 0 ]; then
        apt_get_quiet install sudo
    fi
    hide_output adduser "$USER_ID" sudo
    USER_HOME=`system_get_user_home "$USER_ID"`
    if [ ! -d "$USER_HOME/.ssh" ]; then
        # Control will enter here if $DIRECTORY doesn't exist.
        hide_output sudo -u "$USER_ID" mkdir "$USER_HOME/.ssh"
    fi
    hide_output sudo -u "$USER_ID" touch "$USER_HOME/.ssh/authorized_keys"
    if [ ! -z ${USER_SSHKEY:-} ]; then
        sudo -u "$USER_ID" echo "$USER_SSHKEY" >> "$USER_HOME/.ssh/authorized_keys"
        chmod 0600 "$USER_HOME/.ssh/authorized_keys"
    fi
    infoscreendone
    if [ $SSHD_PASSWORDAUTH == "off" ] && [ -z ${USER_SSHKEY:-} ]; then
    dialog --title "copy client " \
        --colors \
        --msgbox \
"Done on client side now before we securing server\n
\Z4ssh-copy-id $USER_ID@$PUBLIC_IP\n
\n\Z0NOTE: Be sure the client side have openssh\n
\Z4sudo apt-get install openssh-server" 0 0
    fi
else
    infoscreenfailed
fi

infoscreen "securing" "sshd"
update_param_boolean "/etc/ssh/sshd_config" "PermitRootLogin" "$SSHD_PERMITROOTLOGIN"
update_param_boolean "/etc/ssh/sshd_config" "PasswordAuthentication" "$SSHD_PASSWORDAUTH"
systemctl reload sshd
infoscreendone

infoscreen "installing" "fail2ban"
    apt_get_quiet install fail2ban
infoscreendone

infoscreen "installing" "firewall"
    apt_get_quiet install ufw
    hide_output ufw default deny incoming
    hide_output ufw default allow outgoing
    hide_output ufw allow ssh
    hide_output ufw --force enable
infoscreendone

if [ "$SOFTWARE_INSTALL_AJENTI" == "on" ]; then
    infoscreen "installing" "Ajenti control panel"
    case $OS in
    "Debian GNU/Linux")
        hide_output apt-key adv --fetch-keys http://repo.ajenti.org/debian/key
        echo "deb http://repo.ajenti.org/debian main main debian" >> /etc/apt/sources.list.d/ajenti.list
        ;;
    "Ubuntu")
        apt_get_quiet -y install wget
        apt_get_quiet install python python-pil
        hide_output apt-key adv --fetch-keys http://repo.ajenti.org/debian/key
        hide_output wget http://security.ubuntu.com/ubuntu/pool/universe/p/pillow/python-imaging_4.1.1-3build2_all.deb
        hide_output dpkg -i python-imaging_4.1.1-3build2_all.deb
        echo "deb http://repo.ajenti.org/ng/debian main main ubuntu" >> /etc/apt/sources.list.d/ajenti.list
        ;;
    esac
    hide_output apt-get update
    apt_get_quiet install ajenti
    hide_output systemctl start ajenti
    apt_get_quiet install build-essential python-pip python-dev python-lxml libffi-dev libssl-dev libjpeg-dev libpng-dev uuid-dev python-dbus
    hide_output pip install ajenti-panel ajenti.plugin.dashboard ajenti.plugin.settings ajenti.plugin.plugins
    hide_output systemctl enable ajenti
    hide_output systemctl restart ajenti
    hide_output ufw allow 8000
    STR="${WHITE}Ajenti will listen on HTTPS port 8000 by default \nDefault username : root \nDefault password : admin\nhttps://${PUBLIC_IP}:8000"
    MSGBOX+=($STR)
    infoscreendone
fi

if [ "${SOFTWARE_INSTALL_NGINX:-}" == "on" ]; then
    infoscreen "Installing" "nginx Webserver"
    apt_get_quiet install nginx python-certbot-nginx

    mkdir -p /var/www/letsencrypt/.well-known/acme-challenge

    hide_output systemctl enable nginx
    hide_output systemctl start nginx

    hide_output ufw allow "nginx full"

    nginx_create_site $PRIMARY_HOSTNAME ${NGINX_HTML_BASE_DIR:-}
    for HOSTNAME in "${NGINX_SITES_HOSTNAMES[@]}"
    do
        nginx_create_site $HOSTNAME ${NGINX_HTML_BASE_DIR:-}
    done
    infoscreendone
fi

if [ "${SOFTWARE_INSTALL_POSTGRESQL:-}" == "on" ]; then
    infoscreen "Installing" "postgresql database"
    . setup/postgresql.sh
    postgresql_install
    postgresql_create_role "$USER_ID" "$USER_PASSWORD"
    infoscreendone
    STR="${WHITE}Postgresql \nDefault user : ${USER_ID}\nDefault password : same as user password"
    MSGBOX+=($STR)
fi

if [ "${SOFTWARE_INSTALL_MYSQL:-}" == "on" ]; then
    infoscreen "Installing" "mysql database"
    . setup/mysql.sh
    mysql_install
    mysql_set_user_password "root" "$USER_PASSWORD"
    infoscreendone
    STR="${WHITE}Mysql \nDefault username : root \nDefault password : same as user password for ${USER_ID}"
    MSGBOX+=($STR)
fi

infoscreen "Setting" "bash stuff for root - $OS version $OS_VER"
case $OS in
'Debian GNU/Linux'|'Ubuntu')
    # working with Debian 9
    sed -i -e "s/^# export LS_OPTIONS='--color=auto'/export LS_OPTIONS='--color=auto'/" /root/.bashrc
    sed -i -e "s/^# alias l='ls \$LS_OPTIONS -lA'/alias l='ls \$LS_OPTIONS -lA'/" /root/.bashrc
;;
esac
infoscreendone

for i in "${MSGBOX[@]}"
do
    printf "************************************************************************\n"
    printf "$i\n"
    printf "************************************************************************\n\n"
done
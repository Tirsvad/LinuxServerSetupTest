#!/bin/bash

# Setting default values
[ -z "${SSHD_PASSWORDAUTH:-}" ] && SSHD_PASSWORDAUTH=no
[ -z "${SSHD_PERMITROOTLOGIN:-}" ] && SSHD_PERMITROOTLOGIN=no

# If the machine is behind a NAT, inside a VM, etc., it may not know
# its IP address on the public network / the Internet. Ask the Internet
# and possibly confirm with user.
if [ -z "${PUBLIC_IP:-}" ]; then
    # Ask the Internet.
    GUESSED_IP=$(get_publicip_from_web_service 4)

    if [[ -z "${DEFAULT_PUBLIC_IP:-}" && ! -z "${GUESSED_IP:-}" ]]; then
        PUBLIC_IP=$GUESSED_IP
    fi
fi

[ -z "${PUBLIC_IPV6:-}" ] && {
    # Ask the Internet.
    GUESSED_IPV6=$(get_publicip_from_web_service 6)

    if [[ -z "${DEFAULT_PUBLIC_IPV6:-}" && ! -z "${GUESSED_IPV6:-}" ]]; then
        PUBLIC_IPV6=$GUESSED_IPV6
    fi
}

[ ! "${NONINTERACTIVE:-}" == "yes" ] && . setup/questions.sh || {
    # check if all GLOBALS is set
    [ ! -z "${USER_ID:-}" ] && [ ! -z "${USER_PASSWORD:-}" ] || { echo "User credential not set in config file"; exit 1; }
    [ ! "$SSHD_PASSWORDAUTH" == "yes" ] && [ -z "${USER_SSHKEY:-}" ] && { echo -e "Global varible USER_SSHKEY not set in config file.\nBut required as no password is acceptet for login"; exit 1; }
}

[ ! -z "${PRIMARY_HOSTNAME:-}" ] && {
    infoscreen "Setting" "hostname ${PRIMARY_HOSTNAME}"
    # First set the hostname in the configuration file, then activate the setting
    hostnamectl set-hostname $PRIMARY_HOSTNAME
    cp /etc/hosts /etc/hosts.backup
    update_param "/etc/hosts" ${PRIMARY_HOSTNAME} "127.0.0.1"
    infoscreendone
}

infoscreen "Updating" "System and software"
case $OS in
"Debian GNU/Linux")
    install_package_upgrade
    ;;
"Ubuntu")
    install_package_upgrade
    ;;
"CentOS Linux")
    install_package epel-release
    install_package centos-release-scl
    install_package_upgrade
    ;;
esac
infoscreendone

infoscreen "installing" "firewall"
case $OS in
"Debian GNU/Linux"|"Ubuntu")
    install_package ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow SSH
    ufw --force enable
    ;;
"CentOS Linux")
    # centos is already with firewall
    ;;
esac
infoscreendone

infoscreen "Adding" "priviliged user ${USER_ID}"
set +e
id "${USER_ID}" >/dev/null 2>&1
USEREXIST=$?
set -e
if  [ ! $USEREXIST -eq 0  ]; then
    USER_ID=`lower $USER_ID`
    useradd --create-home -s "$USER_SHELL" "$USER_ID"
    echo "$USER_ID:$USER_PASSWORD" | chpasswd
    which sudo
    if [ ! $? -eq 0 ]; then
        install_package sudo
    fi
    case $OS in
    "Debian GNU/Linux")
        adduser "$USER_ID" sudo
        ;;
    "Ubuntu")
        adduser "$USER_ID" sudo
        ;;
    "CentOS Linux")
        usermod -aG wheel "$USER_ID"
        ;;
    esac
    USER_HOME=`system_get_user_home "$USER_ID"`
    if [ ! -d "$USER_HOME/.ssh" ]; then
        # Control will enter here if $DIRECTORY doesn't exist.
        sudo -u "$USER_ID" mkdir "$USER_HOME/.ssh"
    fi
    sudo -u "$USER_ID" touch "$USER_HOME/.ssh/authorized_keys"
    if [ ! -z ${USER_SSHKEY:-} ]; then
        sudo -u "$USER_ID" echo "$USER_SSHKEY" >> "$USER_HOME/.ssh/authorized_keys"
        chmod 0600 "$USER_HOME/.ssh/authorized_keys"
    fi
    infoscreendone
    if [ ! "$SSHD_PASSWORDAUTH" == "yes" ] && [ -z ${USER_SSHKEY:-} ]; then
    [ $(which apt-get) ] && INFO="apt-get" || [ $(which dnf) ] && INFO="dnf" || [ $(which yum) ] && INFO="yum"
    dialog --title "copy client " \
        --colors \
        --msgbox \
"Done on client side now before we securing server\n
\Z4ssh-copy-id $USER_ID@$PUBLIC_IP\n
\n\Z0NOTE: Be sure the client side have openssh\n
\Z4sudo $INFO install openssh-client" 0 0 1>&3
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
install_package fail2ban
systemctl enable fail2ban
infoscreendone

[ "${SOFTWARE_INSTALL_AJENTI:-}" == "on" ] && {
    infoscreen "installing" "Ajenti control panel"
    case $OS in
    "Debian GNU/Linux")
        apt-key adv --fetch-keys http://repo.ajenti.org/debian/key
        echo "deb http://repo.ajenti.org/debian main main debian" >> /etc/apt/sources.list.d/ajenti.list
        install_package_upgrade
        install_package ajenti
        systemctl start ajenti
        install_package build-essential python-pip python-dev python-lxml libffi-dev libssl-dev libjpeg-dev libpng-dev uuid-dev python-dbus
        systemctl enable ajenti
        systemctl restart ajenti
        ufw allow 8000
        ;;
    "Ubuntu")
        install_package wget
        install_package python python-pil
        apt-key adv --fetch-keys http://repo.ajenti.org/debian/key
        wget http://security.ubuntu.com/ubuntu/pool/universe/p/pillow/python-imaging_4.1.1-3build2_all.deb
        dpkg -i python-imaging_4.1.1-3build2_all.deb
        echo "deb http://repo.ajenti.org/ng/debian main main ubuntu" >> /etc/apt/sources.list.d/ajenti.list
        install_package_upgrade
        install_package ajenti
        systemctl start ajenti
        install_package build-essential python-pip python-dev python-lxml libffi-dev libssl-dev libjpeg-dev libpng-dev uuid-dev python-dbus
        systemctl enable ajenti
        systemctl restart ajenti
        ufw allow 8000
        ;;
    "CentOS Linux")
        [[ $(yum list | grep ajenti-repo) ]] || rpm -Uvh http://repo.ajenti.org/ajenti-repo-1.0-1.noarch.rpm # check if repo esist else get it
        [[ $(yum list installed ajenti) ]] || install_package ajenti # check if package is installed else install it
        firewall-cmd --permanent --zone=public --add-port=8000/tcp
        firewall-cmd --reload
        systemctl enable ajenti
        systemctl restart ajenti
        ;;
    esac
    STR="${WHITE}Ajenti will listen on HTTPS port 8000 by default \nDefault username : root \nDefault password : admin\nhttps://${PUBLIC_IP}:8000"
    MSGBOX+=($STR)
    infoscreendone
}

[ "${SOFTWARE_INSTALL_NGINX:-}" == "on" ] && {
    infoscreen "Installing" "nginx Webserver"
    bash $FILE_TOOLS_NGINX_SETUP install
    bash $FILE_TOOLS_NGINX_SETUP add --domain $PRIMARY_HOSTNAME --email $LETSENCRYPT_EMAIL
    [ ! -Z "${NGINX_SITES_HOSTNAMES:-}"] && {
        for HOSTNAME in "${NGINX_SITES_HOSTNAMES[@]}"
        do
            bash $FILE_TOOLS_NGINX_SETUP add --domain $HOSTNAME --email $LETSENCRYPT_EMAIL
        done
    }
    infoscreendone
}

[ "${SOFTWARE_INSTALL_POSTGRESQL:-}" == "on" ] && {
    infoscreen "Installing" "postgresql database"
    case $OS in
    "Debian GNU/Linux")
        install_package postgresql postgresql-contrib
        systemctl start postgresql
        systemctl enable postgresql
        ;;
    "Ubuntu")
        install_package postgresql postgresql-contrib
        systemctl start postgresql
        systemctl enable postgresql
        ;;
    "CentOS Linux")
        install_package postgresql-server postgresql-contrib
        postgresql-setup initdb
        systemctl start postgresql
        systemctl enable postgresql
        ;;
    esac

    cd /
    su postgres bash -c "psql -c \"CREATE USER $USER_ID WITH PASSWORD '$USER_PASSWORD';\""
    cd -
    infoscreendone
    STR="${WHITE}Postgresql \nDefault user : ${USER_ID}\nDefault password : same as user password"
    MSGBOX+=($STR)
}

[ "${SOFTWARE_INSTALL_MYSQL:-}" == "on" ] && {
    infoscreen "Installing" "mysql database"
    . setup/mysql.sh
    mysql_install
    mysql_set_user_password "root" "$USER_PASSWORD"
    infoscreendone
    STR="${WHITE}Mysql \nDefault username : root \nDefault password : same as user password for ${USER_ID}"
    MSGBOX+=($STR)
}

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
    printf "${WHITE}------------------------------------------------------------------------\n" 1>&3
    printf "$i\n" 1>&3
    printf "${WHITE}------------------------------------------------------------------------\n\n" 1>&3
done
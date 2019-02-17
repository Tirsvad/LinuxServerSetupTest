#!/bin/bash

# Define the dialog exit status codes
: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

[ -z "${SSHD_PERMITROOTLOGIN:-}" ] && SSHD_PERMITROOTLOGIN=no
[ -z "${SSHD_PASSWORDAUTH:-}" ] && SSHD_PASSWORDAUTH=no

[ -z "${SOFTWARE_INSTALL_NGINX:-}" ] && SOFTWARE_INSTALL_NGINX=off
[ -z "${SOFTWARE_INSTALL_AJENTI:-}" ] && SOFTWARE_INSTALL_AJENTI=off
[ -z "${SOFTWARE_INSTALL_DB:-}" ] && SOFTWARE_INSTALL_DB=off
[ -z "${SOFTWARE_INSTALL_MYSQL:-}" ] && SOFTWARE_INSTALL_MYSQL=off
[ -z "${SOFTWARE_INSTALL_POSTGRESQL:-}" ] && SOFTWARE_INSTALL_POSTGRESQL=off

# Create a temporary file and make sure it goes away when we're dome
tmp_file=$(tempfile 2>/dev/null) || tmp_file=/tmp/test$$
trap "rm -f $tmp_file" 0 1 2 5 15

function ask_hostname {
    if [ -z "${PRIMARY_HOSTNAME:-}" ]; then
        PRIMARY_HOSTNAME=$DEFAULT_PRIMARY_HOSTNAME
    fi
    dialog --title "Name your host" \
    --inputbox \
    "This host need a name, called a 'hostname'. The name will form a part of the web address.
    \n\nWe recommend that the name be a subdomain of the domain in your email address, so we're suggesting $DEFAULT_PRIMARY_HOSTNAME.
    \n\nYou can change it.
    \n\nHostname:" \
    0 0 $PRIMARY_HOSTNAME 2>$tmp_file 1>&3

    return_value=$?

    case $return_value in
    $DIALOG_OK)
        PRIMARY_HOSTNAME=`cat $tmp_file`
        ;;
    $DIALOG_CANCEL)
        echo "Cancel pressed."
        exit;;
    $DIALOG_ESC)
        if test -s $tmp_file ; then
        cat $tmp_file
        else
        echo "ESC pressed."
        fi
        exit;;
    esac
}

function ask_new_user {
    dialog --backtitle "Linux User Management" --title "Create a privileged user" --ok-label "Submit" \
    --cr-wrap --insecure\
    --mixedform "\nPrivileged user credential" 0 0 0\
    "User id:" 1 1 "${USER_ID:-}" 1 10 25 0 0\
    "Password:" 2 1 "${USER_PASSWORD:-}" 2 10 25 0 1\
    "Password retype:" 3 1 "${USER_PASSWORD:-}" 3 10 25 0 1\
    "shell:" 4 1 "${USER_SHELL:-}" 4 10 25 0 0\
    2>$tmp_file 1>&3

    return_value=$?

    case $return_value in
    $DIALOG_OK)
        lines=( )
        while IFS= read -r line; do
            lines+=( "$line" )
        done < $tmp_file
        USER_ID=${lines[0]:-}
        USER_PASSWORD=${lines[1]:-}
        local password_retype=${lines[2]:-}
        USER_SHELL=${lines[3]:-}
        if [ "$password_retype" == "$USER_PASSWORD" ]; then
            return 1
        else
            return 0
        fi
        ;;
    $DIALOG_CANCEL)
        echo "Cancel pressed."
        exit;;
    $DIALOG_ESC)
        if test -s $tmp_file ; then
        cat $tmp_file
        else
        echo "ESC pressed."
        fi
        exit;;
    esac
}

function ask_secure_sshd {
    local permitrootlogin="off"
    local passwordauth="off"
    [ "$SSHD_PERMITROOTLOGIN" == "yes"  ] && permitrootlogin="on"
    [ "$SSHD_PASSWORDAUTH" == "yes"  ] && passwordauth="on"

    dialog --backtitle "Secure Management" --title "Set sshd settings" --ok-label "submit" --separate-output \
    --checklist "Make your SSH secure. Please don't change unless" 0 0 0 \
    "SSHD_PERMITROOTLOGIN" "Permit root login" $permitrootlogin \
    "SSHD_PASSWORDAUTH" "Password authentication" $passwordauth \
    2>$tmp_file 1>&3

    return_value=$?

    case $return_value in
    $DIALOG_OK)
        lines=( )
        while IFS= read -r line; do
            case $line in
            "SSHD_PERMITROOTLOGIN" )
            SSHD_PERMITROOTLOGIN=yes
            ;;
            "SSHD_PASSWORDAUTH" )
            SSHD_PASSWORDAUTH=yes
            ;;
            esac
        done < $tmp_file
        ;;
    $DIALOG_CANCEL)
        echo "Cancel pressed."
        exit;;
    $DIALOG_ESC)
        if test -s $tmp_file ; then
        cat $tmp_file
        else
        echo "ESC pressed."
        fi
        exit;;
    esac
}

function ask_software_install {
    dialog --backtitle "Software Management" --ok-label "submit" --separate-output \
    --checklist "Which software to install" 0 0 0 \
    "NGINX" "Webserver" $SOFTWARE_INSTALL_NGINX \
    "Ajenti" "Alternativ Cpanel" $SOFTWARE_INSTALL_AJENTI \
    "Database" "We ask for which DB later" $SOFTWARE_INSTALL_DB \
    2>$tmp_file 1>&3

    return_value=$?

    case $return_value in
    $DIALOG_OK)
        while IFS= read -r line; do
            case $line in
            "NGINX" )
            SOFTWARE_INSTALL_NGINX=on
            ;;
            "Ajenti" )
            SOFTWARE_INSTALL_AJENTI=on
            ;;
            "Database" )
            SOFTWARE_INSTALL_DB=on
            ;;
            esac
        done < $tmp_file
        ;;
    $DIALOG_CANCEL)
        echo "Cancel pressed."
        exit;;
    $DIALOG_ESC)
        if test -s $tmp_file ; then
        cat $tmp_file
        else
        echo "ESC pressed."
        fi
        exit;;
    esac
}

function ask_software_db {
    dialog --backtitle "Software Management" --ok-label "submit" \
    --radiolist "Which databse to install" 0 0 0 \
    "Postgresql" "" $SOFTWARE_INSTALL_POSTGRESQL \
    "Mysql" "" $SOFTWARE_INSTALL_MYSQL \
    2>$tmp_file 1>&3

    return_value=$?

    case $return_value in
    $DIALOG_OK)
        local result=`cat $tmp_file`
        case $result in
            "Postgresql" )
            SOFTWARE_INSTALL_POSTGRESQL=on
            ;;
            "Mysql" )
            SOFTWARE_INSTALL_MYSQL=on
            ;;
        esac
        ;;
    $DIALOG_CANCEL)
        echo "Cancel pressed."
        exit;;
    $DIALOG_ESC)
        if test -s $tmp_file ; then
        cat $tmp_file
        else
        echo "ESC pressed."
        fi
        exit;;
    esac
}

function ask_ssl_setup {
    dialog --title "SSL Setup" \
    --inputbox \
    "We need to ensure safe connection between webserver and client. So we setting a SSL connection up.
    \n\nPlease insert an email adress used for issue about the SSL certificate.
    \n\nEmail:" \
    0 0 "" 2> $tmp_file 1>&3

    return_value=$?

    case $return_value in
    $DIALOG_OK)
        LETSENCRYPT_EMAIL=`cat $tmp_file`
        ;;
    $DIALOG_CANCEL)
        echo "Cancel pressed."
        exit;;
    $DIALOG_ESC)
        if test -s $tmp_file ; then
        cat $tmp_file
        else
        echo "ESC pressed."
        fi
        exit;;
    esac
}

if [ -z "${DEFAULT_PRIMARY_HOSTNAME:-}" ]; then
    DEFAULT_DOMAIN_GUESS=$(echo $(get_default_hostname) | sed -e 's/^ebox\.//')
    DEFAULT_PRIMARY_HOSTNAME=$DEFAULT_DOMAIN_GUESS
fi

if [ ! -f /usr/bin/dialog ] || [ ! -f /usr/bin/python3 ] || [ ! -f /usr/bin/pip3 ]; then
    infoscreen "Installing" "packages needed for Dialog"
    install_package dialog || exit 1
    infoscreendone
fi

dialog --title "Linux server setup" \
--msgbox \
"Hello and thanks for deploying the Linux Server Setup Script
\n\nI'm going to ask you a few questions.
\n\nNOTE: You should only install this on a brand new Debian or combatible distrobution installation." 0 0 1>&3

ask_hostname

while ask_new_user
do
    dialog --title "Linux server setup" \
    --msgbox \
    "Password did not match" 0 0 1>&3
done

ask_secure_sshd
ask_software_install

[ $SOFTWARE_INSTALL_DB == "on" ] && ask_software_db

if [ -z "${LETSENCRYPT_EMAIL:-}" ]; then
    if [ "$SOFTWARE_INSTALL_NGINX"=="on" ] || [ "$SOFTWARE_INSTALL_AJENTI"=="on" ]; then
        ask_ssl_setup
    fi
fi
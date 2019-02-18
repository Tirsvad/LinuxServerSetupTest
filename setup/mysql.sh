#!/bin/bash

function mysql_install {
    case $OS in
    "Debian GNU/Linux"|"Ubuntu")
        install_package mysql-server
        ;;
    "CentOS Linux")
        wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
        rpm -ivh mysql-community-release-el7-5.noarch.rpm
        yum update
        install_package mysql-server
        systemctl start mysqld
        ;;
    esac
}

function mysql_set_user_password {
    # $1 user
    # $2 password
    mysqladmin -u $1 password $2
}
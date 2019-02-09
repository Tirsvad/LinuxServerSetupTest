#!/bin/bash

function mysql_install {
    apt_get_quiet -y install mysql-server
}

function mysql_set_user_password {
    # $1 user
    # $2 password
    mysqladmin -u $1 password $2
}
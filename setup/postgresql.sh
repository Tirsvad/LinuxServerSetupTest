#!/bin/bash

function postgresql_install {
    apt_get_quiet install postgresql postgresql-contrib
    systemctl start postgresql
}

function postgresql_create_role {
    # $1 user name
    # $2 user passsword
    [ -z ${1:-} ] && [ -z ${2:-} ] && { echo "Missing user name and user password as arguments" >&2; exit 1; }
    [ -z ${1:-} ] && { echo "Missing user name as argument" >&2; exit 1; }
    [ -z ${2:-} ] && { echo "Missing user password as argument" >&2; exit 1; }
    cd /
    su postgres bash -c "psql -c \"CREATE USER $1 WITH PASSWORD '$2';\""
    cd -
}

function postgresql_create_db {
    #$1 db name
    [ -z ${1:-} ] && { echo "Missing database name as argument" >&2; exit 1; }
    cd /
    su postgres bash -c "psql -c \"CREATE DATABASE $1;\""
    cd -
}

function postgresql_grant_all_privileges {
    #$1 db user
    #$2 db name
    cd /
    su postgres bash -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE $2 to $1;\""
    cd -
}
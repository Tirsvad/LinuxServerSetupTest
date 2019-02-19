#!/bin/bash
. setup/function.sh

function django_install {
    # $1 projects path
    # $2 djange app path
    # $3 virtual env path

    [ $(which python3) ] || apt_get_quiet install python3
    [ $(which pip3) ] || apt_get_quiet install -y python3-pip
    [ $(which virtualenv) ] || hide_output pip3 install virtualenv

}
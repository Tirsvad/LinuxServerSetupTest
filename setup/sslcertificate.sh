#!/bin/bash

function sslcertificate {
    # REquired no prosses listen to port 80
    # $1 required a hostname
    # s2 required a email adress
    if [ ! -d "/var/www/letsencrypt/" ]; then
        mkdir -p /var/www/letsencrypt/
    fi
    hide_output eval "certbot --nginx --redirect --keep-until-expiring --non-interactive --agree-tos -m $2 -d $1"
}

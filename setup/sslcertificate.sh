#!/bin/bash

function sslcertificate {
    # Required no prosses listen to port 80
    # $1 required a hostname
    # s2 required a email adress
    [ ! -d "/var/www/letsencrypt/" ] && mkdir -p /var/www/letsencrypt/

    hide_output eval "certbot --nginx --redirect --keep-until-expiring --non-interactive --agree-tos -m $2 -d $1"
}

#!/bin/bash

function nginx_create_site {
    local domain=${1:-}
    local rootPath=${2:-}
    local sitesEnablePath='/etc/nginx/sites-enabled/'
    local sitesAvailablePath='/etc/nginx/sites-available/'
    local baseWwwPath='/var/www/'
    local publicPath="public/"
    local indexhtml="index.html"

    [ -e /etc/nginx/sites-enabled/default ] && rm /etc/nginx/sites-enabled/default

    maindomain=$(sed -e 's|^[^/]*//||' -e 's|/.*$||' <<< ${domain%/*})
    path=$(sed 's/.*\.\(.*\..*\)/\1/' <<< ${maindomain%/*})
    baseWwwPath="$baseWwwPath$path/"
    rootPath="$domain/"

    ### check if domain already exists
    if [ -e $sitesAvailablePath$domain ]; then
        echo -e $"This domain already exists."
        return 1;
    fi

    ### check if directory exists or not
    if ! [ -d $baseWwwPath$rootPath$publicPath ]; then
        mkdir -p $baseWwwPath$rootPath$publicPath
    fi

    cp conf/nginx_domian.conf $sitesAvailablePath$domain
    sed -i -e 's/\$domain/'"${domain}"'/g' $sitesAvailablePath$domain
    ln -s $sitesAvailablePath$domain $sitesEnablePath$domain
    systemctl reload nginx
    sslcertificate ${domain} $LETSENCRYPT_EMAIL

    if ! echo "<html>
        <head>
            <title>Welcome to $domain!</title>
        </head>
        <body>
            <h1>Success!  The $domain server block is working!</h1>
        </body>
    </html>" > "$baseWwwPath$rootPath$publicPath$indexhtml"
    then
        echo -e $"There is an ERROR when create index.html file"
        return 1;
    fi

    cp conf/nginx_domian_ssl.conf $sitesAvailablePath$domain
    sed -i -e 's/\$domain/'"${domain}"'/g' $sitesAvailablePath$domain
    sed -i -e 's|\$baseWwwPath|'${baseWwwPath}'|g' $sitesAvailablePath$domain
    sed -i -e 's|\$rootPath|'${rootPath}'|g' $sitesAvailablePath$domain
    sed -i -e 's|\$publicPath|'${publicPath}'|g' $sitesAvailablePath$domain
    systemctl reload nginx
}
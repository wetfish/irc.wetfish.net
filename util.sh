#!/bin/bash
source config.sh

printf -v joined_domains "%s -d " "${domain[@]}"

check_root () {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

if [ -z "$name" ] || [ -z "$domain" ] || [ -z "$email" ]; then
    echo -e "\033[0;31mMissing configuration options, please modify config.sh\033[0m"
    exit
fi

if [ ! -z "$acmehost" ]; then
    if [ ! -f /etc/letsencrypt/acme-dns-auth.py ]; then 
        curl --create-dirs -o /etc/letsencrypt/acme-dns-auth.py https://raw.githubusercontent.com/joohoi/acme-dns-certbot-joohoi/master/acme-dns-auth.py
        chmod 0700 /etc/letsencrypt/acme-dns-auth.py
    fi
    usingAcmeDns=true;
    else
    usingAcmeDns=false;
fi

acquire_certs () {
    if $usingAcmeDns; then
        ## Update acme-dns config in hook script in case we've changed it in config.sh..
        sed -i "1,/.*ACMEDNS_URL.*/{s/.*ACMEDNS_URL.*/ACMEDNS_URL = \"https:\/\/$acmehost\"/;}" /etc/letsencrypt/acme-dns-auth.py
        certbot certonly --force-renewal --agree-tos --manual-public-ip-logging-ok -m $email --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d ${joined_domains%-d }
    else
        certbot certonly --force-renewal --agree-tos --non-interactive --standalone -m $email -d ${joined_domains%-d }
    fi
}

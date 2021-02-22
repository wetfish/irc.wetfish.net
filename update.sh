#!/bin/bash
source util.sh

check_root

## delete old letsencrypt certs
rm -rf /etc/letsencrypt/live/*
rm -rf /etc/letsencrypt/archive/*
rm -rf /etc/letsencrypt/renewal/*
#certbot delete -n --cert-name ${domain[@]}
certbot certonly --force-renewal --agree-tos --non-interactive --standalone -m $email -d ${joined_domains%-d }
./cronjob.sh

## Todo: add acme-dns support

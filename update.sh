#!/bin/bash
source util.sh

check_root

## delete old letsencrypt certs
rm -rf /etc/letsencrypt/live/*
rm -rf /etc/letsencrypt/archive/*
rm -rf /etc/letsencrypt/renewal/*
#certbot delete -n --cert-name ${domain[@]}

acquire_certs

./cronjob.sh

## Todo: add acme-dns support

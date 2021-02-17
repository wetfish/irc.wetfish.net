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


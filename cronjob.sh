#!/bin/bash

# This script is important, don't delete it!!
#
# This script runs on initial install and after a certbot renewal succeeds
# and means you won't have to worry about restarting services manually to enable updated certificates

source config.sh

# delete the old certs..
rm -rf /home/$name/irc.wetfish.net/certs/*
rm -f /home/$name/irc.wetfish.net/inspircd/conf/private/fullchain.pem
rm -f /home/$name/irc.wetfish.net/inspircd/conf/private/privkey.pem
rm -f /home/$name/irc.wetfish.net/thelounge/conf/private/fullchain.pem
rm -f /home/$name/irc.wetfish.net/thelounge/conf/private/privkey.pem

# copy the updated certs..
cp /etc/letsencrypt/live/$domain/* /home/$name/irc.wetfish.net/certs
chown -R $name:$name /home/$name/irc.wetfish.net
chmod -R u=rw,og=r,a+X /home/$name/irc.wetfish.net/
cp /home/$name/irc.wetfish.net/certs/fullchain.pem /home/$name/irc.wetfish.net/inspircd/conf/private/fullchain.pem
cp /home/$name/irc.wetfish.net/certs/privkey.pem /home/$name/irc.wetfish.net/inspircd/conf/private/privkey.pem
cp /home/$name/irc.wetfish.net/certs/fullchain.pem /home/$name/irc.wetfish.net/thelounge/conf/private/fullchain.pem
cp /home/$name/irc.wetfish.net/certs/privkey.pem /home/$name/irc.wetfish.net/thelounge/conf/private/privkey.pem

# Rehash.
docker exec `docker ps -aqf "name=ircwetfishnet_inspircd"` ./inspircd rehash
docker restart `docker ps -aqf "name=ircwetfishnet_nginx"`

#!/bin/bash

source util.sh

check_root

GREEN='\033[0;32m'
NC='\033[0m'

apt-get install -y docker docker-compose certbot

acquire_certs

printf "${GREEN}Creating ${name} user${NC}\n"

adduser --disabled-password --gecos "" $name && usermod -aG docker $name

printf "${GREEN}The user ${name} has been created and added to the Docker group${NC}\n"

mkdir -p /home/$name/irc.wetfish.net/certs
cp -r ./ /home/$name/irc.wetfish.net/

cp /etc/letsencrypt/live/$domain/* /home/$name/irc.wetfish.net/certs
chown -R $name:$name /home/$name/irc.wetfish.net
# Make privkey readable by docker
chmod 644 /home/$name/irc.wetfish.net/certs/privkey.pem
cp /home/$name/irc.wetfish.net/certs/fullchain.pem /home/$name/irc.wetfish.net/inspircd/conf/private/fullchain.pem
cp /home/$name/irc.wetfish.net/certs/privkey.pem /home/$name/irc.wetfish.net/inspircd/conf/private/privkey.pem
cp /home/$name/irc.wetfish.net/certs/fullchain.pem /home/$name/irc.wetfish.net/thelounge/conf/private/fullchain.pem
cp /home/$name/irc.wetfish.net/certs/privkey.pem /home/$name/irc.wetfish.net/thelounge/conf/private/privkey.pem

printf "${GREEN}Generating DH parameters..${NC}\n"
openssl dhparam -out /home/$name/irc.wetfish.net/inspircd/conf/private/dhparams.pem 2048

printf "${GREEN}Setting up crontab${NC}\n"
echo "0 0 * * * root (cd $PWD && certbot renew --deploy-hook \"$PWD/cronjob.sh\")" > /etc/cron.d/irc.wetfish.net

printf "${GREEN}Everything looks good! Now, you can run everything with docker-compose up, assuming you've edited the proper config files${NC}\n"

cd /home/$name/irc.wetfish.net/ && su $name

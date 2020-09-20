#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

source config.sh

if [[ -z "$name" ]]; then
	echo "Please enter a username for the docker user: "
	read name
fi

if [[ -z "$domain" ]]; then
	echo "Please enter the domain name for this server: "
	read domain
fi

if [[ -z "$email" ]]; then
	echo "Please enter the email address for the certificate: "
	read email
fi

GREEN='\033[0;32m'
NC='\033[0m'

apt-get install -y docker docker-compose certbot

certbot certonly --force-renewal --agree-tos --non-interactive --standalone -m $email -d $domain --cert-path ./tmp/certs

printf "${GREEN}Creating ${name} user${NC}\n"

id $name
if [[ $? -eq 0 ]]; then
	adduser $name
fi
usermod -aG docker $name

printf "${GREEN}The user ${name} has been created and added to the Docker group${NC}\n"

mkdir -p /home/$name/irc.wetfish.net/certs
cp --parents -r ./nginx/conf /home/$name/irc.wetfish.net/
cp --parents -r ./thelounge/conf /home/$name/irc.wetfish.net/
cp --parents -r ./inspircd/conf /home/$name/irc.wetfish.net/
cp ./docker-compose.yml /home/$name/irc.wetfish.net/

cp /etc/letsencrypt/live/$domain/* /home/$name/irc.wetfish.net/certs
chown -R $name:$name /home/$name/irc.wetfish.net
chmod -R u=rw,og=r,a+X /home/$name/irc.wetfish.net/
cp /home/$name/irc.wetfish.net/certs/fullchain.pem /home/$name/irc.wetfish.net/inspircd/conf/private/fullchain.pem
cp /home/$name/irc.wetfish.net/certs/privkey.pem /home/$name/irc.wetfish.net/inspircd/conf/private/privkey.pem
cp /home/$name/irc.wetfish.net/certs/fullchain.pem /home/$name/irc.wetfish.net/thelounge/conf/private/fullchain.pem
cp /home/$name/irc.wetfish.net/certs/privkey.pem /home/$name/irc.wetfish.net/thelounge/conf/private/privkey.pem

printf "${GREEN}Generating DH parameters..${NC}\n"
openssl dhparam -out /home/$name/irc.wetfish.net/inspircd/conf/private/dhparams.pem 2048

printf "${GREEN}Setting up crontab${NC}\n"
crontab -l | cat; echo "0 0 * * * certbot renew --deploy-hook \"~/irc.wetfish.net/cronjob.sh\"" | crontab -

printf "${GREEN}Everything looks good! Now, you can run everything with docker-compose up, assuming you've edited the proper config files${NC}\n"

rm -rf ./tmp
cd /home/$name/irc.wetfish.net/ && su $name

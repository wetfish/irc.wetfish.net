#!/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

GREEN='\033[0;32m'
NC='\033[0m'
uname='ircd'

apt-get install -y docker docker-compose certbot

printf "${GREEN}Running certbot.\nPlease enter an email address: ${NC}"
read email
printf "\n"
printf "${GREEN}Please enter the domain name for this server: ${NC}"
read domain
printf "\n"

mkdir -p ./tmp/certs
certbot certonly --force-renewal --agree-tos --non-interactive --standalone -m $email -d $domain --cert-path ./tmp/certs

printf "${GREEN}Creating ircd user${NC}\n"

id $uname
if [[ $? -eq 0 ]]; then
	adduser $uname
fi
usermod -aG docker $uname

printf "${GREEN}The user ${uname} has been created and added to the Docker group${NC}\n"

mkdir -p /home/$uname/irc.wetfish.net/certs
cp -r ./nginx /home/$uname/irc.wetfish.net/
cp -r ./thelounge /home/$uname/irc.wetfish.net/
cp -r ./inspircd /home/$uname/irc.wetfish.net/
cp ./docker-compose.yml /home/$uname/irc.wetfish.net/

cp ./tmp/certs/* /home/$uname/irc.wetfish.net/certs
chown -R $uname:$uname /home/$uname/irc.wetfish.net
chmod -R u=rw,og=r,a+X /home/$uname/irc.wetfish.net/
cp /home/$uname/irc.wetfish.net/certs/fullchain.pem /home/$uname/irc.wetfish.net/inspircd/conf/private/fullchain.pem
cp /home/$uname/irc.wetfish.net/certs/privkey.pem /home/$uname/irc.wetfish.net/inspircd/conf/private/privkey.pem
cp /home/$uname/irc.wetfish.net/certs/fullchain.pem /home/$uname/irc.wetfish.net/thelounge/conf/private/fullchain.pem
cp /home/$uname/irc.wetfish.net/certs/privkey.pem /home/$uname/irc.wetfish.net/thelounge/conf/private/privkey.pem

printf "${GREEN}Generating dhparams..${NC}\n"
openssl dhparam -out /home/$uname/irc.wetfish.net/inspircd/conf/private/dhparams.pem 2048

printf "${GREEN}Everything looks good! Now, you can run everything with docker-compose up, assuming you've edited the proper config files${NC}\n"

rm -rf ./tmp
cd /home/$uname/irc.wetfish.net/ && su $uname

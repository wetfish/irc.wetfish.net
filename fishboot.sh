#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

printf "${GREEN}Hi! I'm an interactive bootstrap script, but you can call me Fishboot. I'm gonna help you get set up :)${NC}\n"
printf "${GREEN}Please enter the name of the unprivileged user you'd like to create${NC}\n"

read uname

adduser $uname --uid 1337 && usermod -aG docker $uname

printf "${GREEN}" "The user"  $uname "has been created and added to the Docker group${NC}\n"
printf "${GREEN}Let me clone the ircd repo for you real quick!${NC}\n"

git -C /home/$uname/ clone -b feature/docker-compose https://github.com/wetfish/irc.wetfish.net/

printf "${GREEN}Please point me to the folder where fullchain.pem and privkey.pem live${NC}\n"
printf "${GREEN}For example, if you used certbot, your certs may lie in /etc/letsencrypt/live/subdomain.wetfish.net${NC}\n"

read certfolder

printf "${GREEN}Fishboot here, I'm copying those files over for you and doing a little ownership/permission changing to make things easier${NC}\n"

mkdir /home/$uname/irc.wetfish.net/certs
cp $certfolder/* /home/$uname/irc.wetfish.net/certs
chown -Rv $uname:$uname /home/$uname/irc.wetfish.net
chmod -Rv u=rw,og=r,a+X /home/$uname/irc.wetfish.net/
cp /home/$uname/irc.wetfish.net/certs/fullchain.pem /home/$uname/irc.wetfish.net/inspircd/conf/private/fullchain.pem
cp /home/$uname/irc.wetfish.net/certs/privkey.pem /home/$uname/irc.wetfish.net/inspircd/conf/private/privkey.pem
cp /home/$uname/irc.wetfish.net/certs/fullchain.pem /home/$uname/irc.wetfish.net/thelounge/conf/private/fullchain.pem
cp /home/$uname/irc.wetfish.net/certs/privkey.pem /home/$uname/irc.wetfish.net/thelounge/conf/private/privkey.pem

printf "${GREEN}Now that that's all done I'm gonna go ahead and build those Docker images for you!${NC}\n"

docker build . -t thelounge:latest -f /home/$uname/irc.wetfish.net/thelounge/Dockerfile
docker build . -t inspircd:latest -f /home/$uname/irc.wetfish.net/inspircd/Dockerfile

printf "${GREEN}Everything looks good! Now, you can run everything with docker-compose up, assuming you've edited the proper config files${NC}\n"
printf "${GREEN}Fishboot out, peace!${NC}\n"

cd /home/$uname/irc.wetfish.net/ && su $uname

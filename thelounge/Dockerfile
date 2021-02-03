FROM debian:buster
#MAINTAINER Yam (yam@wetfish.net)

RUN apt update && apt-get install -y apt-transport-https \
	&& apt-get -y install gnutls-bin certbot nodejs npm curl \
	&& curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
	&& echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/$ \
	&& apt update && apt-get -y install git \
	&& npm install -g yarn \
	&& rm -rf /var/lib/apt/lists/*

RUN addgroup --system --gid 1000 thelounge
RUN adduser --system --uid 1337  --group thelounge
USER thelounge
WORKDIR /home/thelounge

# This may all be best served by moving into the entrypoint itself
# Something like this in /setup.sh

##!/bin/sh 
#git clone https://github.com/thelounge/thelounge && cd thelounge || exit 1
#yarn install
#NODE_ENV=production yarn build
#yarn link
#mkdir -p /home/thelounge/.thelounge/private

# Then, we could use the following: 

#WORKDIR /home/thelounge/thelounge
#EXPOSE 9000
#ENTRYPOINT["/setup.sh"]
#
#CMD["yarn, "start"]

# What this would let us do, is mess with things if the yarn bits change, or to take it out of production trivially (simply provide a different entrypoint in the docker-compose.yml file)

RUN git clone https://github.com/thelounge/thelounge \
	&& cd thelounge \
	&& yarn install \
	&& NODE_ENV=production yarn build \
	&& yarn link \
	&& mkdir -p /home/thelounge/.thelounge/private

WORKDIR /home/thelounge/thelounge
EXPOSE 9000
ENTRYPOINT ["yarn", "start"]

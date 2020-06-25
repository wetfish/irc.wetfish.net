FROM debian:buster
MAINTAINER Taegan (taegan@csag.network)
RUN apt update && apt-get install -y apt-transport-https
RUN apt-get -y install gnutls-bin certbot nodejs npm curl
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/$
RUN apt update && apt-get -y install git
RUN npm install -g yarn
RUN addgroup --system --gid 1000 thelounge
RUN adduser --system --uid 1000 --home /thelounge/ --group thelounge
USER thelounge
WORKDIR /thelounge/
RUN git clone https://github.com/thelounge/thelounge
WORKDIR /thelounge/thelounge/
RUN yarn install
RUN NODE_ENV=production yarn build
RUN yarn link
EXPOSE 9000
RUN mkdir /thelounge/.thelounge/
RUN mkdir /thelounge/.thelounge/private
USER thelounge
ENTRYPOINT ["yarn", "start"]

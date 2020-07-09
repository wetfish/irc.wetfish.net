FROM debian:buster
MAINTAINER Taegan (taeganavery@pm.me)
RUN apt update && apt-get install -y apt-transport-https
RUN apt-get -y install wget build-essential tar pkg-config gnutls-bin libgnutls28-dev certbot wget
RUN wget https://github.com/inspircd/inspircd/archive/v3.6.0.tar.gz
RUN tar -xvf v3.6.0.tar.gz
WORKDIR inspircd-3.6.0/
RUN addgroup --system --gid 10000 inspircd
RUN adduser --system --uid 10000 --home /inspircd/ --group inspircd
RUN ./configure --prefix /inspircd --uid 10000 --gid 10000
RUN make
RUN make install
USER inspircd
EXPOSE 6667 6697 7000 7001 7005
ENTRYPOINT ["/inspircd/bin/inspircd", "--config", "/inspircd/conf/public/inspircd.conf", "--nofork"]
WORKDIR /inspircd
USER root
RUN chmod -R 644 /inspircd/conf
USER inspircd

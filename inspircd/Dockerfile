FROM debian:buster
#MAINTAINER Yam (yam@wetfish.net)

RUN apt update && apt-get install -y \
	apt-transport-https \
	wget \
	build-essential \
	tar \
	pkg-config \
	gnutls-bin \
	libgnutls28-dev \
	certbot \
	&& wget -O - https://github.com/inspircd/inspircd/archive/v3.6.0.tar.gz | tar zxf - \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR inspircd-3.6.0/
RUN addgroup --system --gid 10000 inspircd
RUN adduser --system --uid 10000 --home /inspircd/ --group inspircd
RUN ./configure --prefix /inspircd --uid 10000 --gid 10000 \
	&& make \
	&& make install \
	&& chmod -R 644 /inspircd/conf \
	&& make clean

WORKDIR /inspircd

EXPOSE 6667 6697 7000 7001 7005
USER inspircd
ENTRYPOINT ["/inspircd/bin/inspircd", "--nofork"]

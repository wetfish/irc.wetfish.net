###############################################################################
# INSPIRCD 4.8.0 — RUNTIME-ONLY DOCKER IMAGE
#
# This image installs InspIRCd from the official .deb package:
#   https://github.com/inspircd/inspircd/releases/download/v4.8.0/...
#
# Key Features:
#   - Uses Debian 12 (Bookworm) slim
#   - Installs official amd64 .deb package
#   - Creates dedicated inspircd user/group
#   - Forces linux/amd64 (compatible with M1 under emulation)
#   - No build tools included → secure + minimal
###############################################################################
FROM --platform=linux/amd64 debian:bookworm-slim

LABEL maintainer="cyba <eva.evergreene@protonmail.com>"

###############################################################################
# INSTALL RUNTIME DEPENDENCIES ONLY
###############################################################################
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnutls-bin \
    libgnutls30 \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

###############################################################################
# DOWNLOAD & INSTALL OFFICIAL INSPIRCD RELEASE PACKAGE
###############################################################################
ARG INSPIRCD_VERSION=4.8.0
ARG INSPIRCD_DEB="inspircd_${INSPIRCD_VERSION}.deb12u2_amd64.deb"

# Download .deb into /tmp
RUN wget -O /tmp/${INSPIRCD_DEB} \
    https://github.com/inspircd/inspircd/releases/download/v${INSPIRCD_VERSION}/${INSPIRCD_DEB}

# Install InspIRCd
RUN dpkg -i /tmp/${INSPIRCD_DEB} || apt-get -f install -y

###############################################################################
# CREATE NON-ROOT USER
###############################################################################
RUN groupadd -g 10000 inspircd && \
    useradd  -u 10000 -d /inspircd -g inspircd -s /usr/sbin/nologin inspircd

# Ensure directories are owned correctly
RUN chown -R inspircd:inspircd /inspircd

###############################################################################
# CONTAINER RUNTIME CONFIG
###############################################################################
WORKDIR /inspircd
USER inspircd

# Expose IRC & TLS ports
EXPOSE 6667 6697 7000 7001 7005

###############################################################################
# DEFAULT ENTRYPOINT
# InspIRCd must run in the foreground in Docker, so --nofork is required.
###############################################################################
ENTRYPOINT ["/usr/sbin/inspircd", "--nofork"]

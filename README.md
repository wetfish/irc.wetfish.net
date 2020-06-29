# Dockerized InspIRCd & TheLounge

This has been tested and run on Debian 10 systems, dependencies may differ with other distros and/or versions

## Dependencies
You'll want to update repos and  install ``docker, docker-compose, certbot, git``

#### Initial setup
Get LetsEncrypt certs, run ``certbot certonly``

Create an unprivileged user and add them to the docker group, ``adduser ircd && usermod -aG docker ircd``

Switch to the newly created user and its home directory, ``su ircd`` ``cd``

Clone this repo! ``git clone https://github.com/wetfish/irc.wetfish.net``

Make a directory within ~/irc.wetfish.net named /certs, ``mkdir certs``

Switch to root (or, optionally, a sudo privileged user), ``exit``

Copy the certs to /home/ircd/irc.wetfish.net/certs, i.e. ``cp /etc/letsencrypt/live/subdomain.wetfish.net/* /home/ircd/irc.wetfish.net/certs``

Change the owner of /certs and its files to ircd, ``chown -Rv ircd:ircd /home/ircd/irc.wetfish.net/certs``

Change permissions on /certs, ``chmod 0644 /home/ircd/irc.wetfish.net/certs/*``

Switch back to the user ircd, ``su ircd``

Move into InspIRCd's private folder, where it reads certs from, ``cd ~/irc.wetfish.net/inspircd/conf/private``

Symlink the contents of /certs to the folder, ``ln -s /home/ircd/irc.wetfish.net/certs/* ./``

Move into TheLounge's private folder, where it reads certs from, ``cd ~/irc.wetfish.net/thelounge/conf/private``

Symlink the contents of /certs in the same fashion, ``ln -s /home/ircd/irc.wetfish.net/certs/* ./``

#### Building the images and stuff

Move into ~/irc.wetfish.net/thelounge and build TheLounge, ``docker build -t thelounge:latest .``

Move into ~/irc.wetfish.net/inspircd and build InspIRCd, ``docker build -t inspircd:latest .``

#### Edting file configurations

You'll want to edit and rename the InspIRCd, TheLounge, and Nginx private subdirectory config files to match your needs.

#### Everything can now be run from ~/irc.wetfish.net with ``docker-compose up``

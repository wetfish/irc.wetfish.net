# Dockerized InspIRCd & TheLounge

After initial setup, this should be able to be run with a simple ``docker-compose up``

## Dependencies
You'll want to install ``docker, docker-compose, certbot``

#### Initial setup
Get LetsEncrypt certs, run ``certbot certonly``

Make a directory within ~/irc.wetfish.net named /certs, ``mkdir certs``

Copy fullchain.pem and privkey.pem to ~/irc.wetfish.net/certs

Change the owner of /certs and its files to your local user and group, i.e. ``chown -R user:group certs/``

Change permissions on /certs, ``chmod -R 644 certs/``

Copy fullchain.pem and privkey.pem from ~/irc.wetfish.net/certs to /inspircd/conf/private and /thelounge/conf/private

#### Building the images and stuff

Move into ~/irc.wetfish.net/thelounge and build TheLounge, ``docker build -t thelounge:latest .``

Move into ~/irc.wetfish.net/inspircd and build InspIRCd, ``docker build -t inspircd:latest .``

#### Edting file paths and configurations

You'll want to edit and rename the InspIRCd, TheLounge, and Nginx private subdirectory config files to match your needs.

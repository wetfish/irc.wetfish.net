# Dockerized InspIRCd & TheLounge

After initial setup, ircdocker should be able to be run with a simple ``docker-compose up``

## Dependencies
You'll want to install ``docker, docker-compose, certbot``

#### Initial setup
Clone this repo, ``git clone https://github.com/taeganb/ircdocker.git``

Get LetsEncrypt certs, run ``certbot certonly``

Make a directory within ~/ircdocker named /certs, ``mkdir certs``

Copy fullchain.pem and privkey.pem to ~/ircdocker/certs

Change permissions on /certs, ``chmod -R 640 certs/``

Copy fullchain.pem and privkey.pem from ~/ircdocker/certs/ to /inspircd/conf/private and /thelounge/conf/private

#### Building the images and stuff

Move into ~/ircdocker/thelounge and build TheLounge, ``docker build -t thelounge:latest .``

Move into ~/ircdocker/inspircd and build InspIRCd, ``docker build -t inspircd:latest .``

#### Edting file paths and configurations

You'll want to edit the InspIRCd, TheLounge, and Nginx private subdirectory config files to match your needs, as well as docker-compose.yml

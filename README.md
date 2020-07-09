# Dockerized InspIRCd & TheLounge

This has been tested and run on Debian 10 systems, dependencies may differ with other distros and/or versions

## Dependencies
Run ``sudo apt install docker docker-compose certbot git``

#### Initial setup - don't clone the repo, fishboot does it for you!
Grab fishboot.sh and make it executable with ``chmod +x fishboot.sh``, then run it with ``sudo ./fishboot.sh``

#### Edting file configurations
You'll want to edit and rename the InspIRCd, TheLounge, and Nginx private subdirectory config files to match your needs.

#### Everything can now be run from ~/irc.wetfish.net with ``docker-compose up``

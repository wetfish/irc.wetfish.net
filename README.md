# Dockerized InspIRCd & TheLounge

This has been tested and run on Debian 10 systems, dependencies may differ with other distros and/or versions

#### Instructions
1. Clone this repo:   
`git clone https://github.com/wetfish/irc.wetfish.net.git; cd irc.wetfish.net`

2. Rename config.sh.example to config.sh and modify the values:  
`cp config.example.sh config.sh; nano config.sh`

3. Execute install.sh:  
`./install.sh`

#### Edting file configurations
You'll want to edit and rename the InspIRCd, TheLounge, and Nginx private subdirectory config files to match your needs.

#### Everything can now be run from the install users ~/irc.wetfish.net with ``docker-compose up``

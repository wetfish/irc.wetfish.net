# Usage

Type './irc' to initialize the repository and start the server. Note that only 
the first build will be slow -- succeeding builds will be much faster.

Type './irc help' for a list of all commands for controlling the server.

To add/update a custom module, place its source code into the ./modules 
directory, then run './irc refresh modules'. This will restart the server.

To apply any changes made in the conf-private or conf-public directories, run 
'./irc refresh conf'. This will also restart the server.

# Notes

Some configuration options are available for the ./irc program. They're in the 
first few lines of that program. Open it in a text editor to change them.

Dockerfile, entrypoint.sh, and all files inside of the conf-public directory 
originally taken from [here](https://github.com/Adam-/inspircd-docker).

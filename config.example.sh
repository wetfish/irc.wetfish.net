#!/bin/bash
# Probably shouldn't change user after install.
name='user'
# If you change these after install, run update.sh to apply new certs.
domain=('domain' 'optional' 'domains')
email='admin@domain.com'
# Don't include http(s):// or www. in the host.
acmehost='auth.domain.com'

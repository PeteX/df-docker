#!/bin/bash

# update site configuration
# if no servername is provided use dreamfactory.local as default
sed -i "s;%SERVERNAME%;${SERVERNAME:=dreamfactory.app};g" /etc/apache2/sites-available/dreamfactory.conf

#
# start Apache
exec /usr/sbin/apachectl -e info -DFOREGROUND

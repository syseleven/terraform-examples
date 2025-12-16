#!/bin/sh

apt -q update
apt -q -y install nginx

echo `hostname` > /var/www/html/index.html


#!/bin/sh

apt-get -q update
apt-get -q -y install curl apache2 php7.4-fpm libapache2-mod-php7.4

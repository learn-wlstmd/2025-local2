#!/bin/bash
yum install -y httpd

service httpd start

echo "Welcome to the ws portal" > /var/www/html/index.html

sudo dnf install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm

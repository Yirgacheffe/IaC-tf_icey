#!/bin/bash

# do update and install apache2
sudo apt update -y
sudo apt install apache2 -y

# start web server
sudo systemctl start apache2
sudo bash -c 'echo icey web server running > /var/www/html/index.html'

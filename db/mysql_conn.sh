#!/bin/bash

# Connect to RDS according to the env value, execute sql scripts in $1 
mysql -h ${DB_HOST} -P 3306 -u ${DB_USER} -p < $1

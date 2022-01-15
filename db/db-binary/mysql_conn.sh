#!/bin/bash
RDS_HOST="mysql-icey-1.clkcufuco2l8.ap-southeast-1.rds.amazonaws.com"

# O l e g # local1234
mysql -h ${RDS_HOST} -P 3306 -u admin -p

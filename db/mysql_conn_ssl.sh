#!/bin/bash

mysql --host="${DB_HOST}" \
      --port=3306 \
      --user=legofun \
      --ssl-ca=/var/mysql-certs/rds-combined-ca-bundle.pem \
      --ssl-verify-server-cert \
      --password="$TOKEN"

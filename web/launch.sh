#!/bin/bash

# Set web port and load balance endpoint
ADDR=":80"
URL="http://internal-app-lb-92960804.ap-southeast-1.elb.amazonaws.com:80/api/notes"

sudo -E ./web-demo-linux -addr=${ADDR} -api-url=${URL} &

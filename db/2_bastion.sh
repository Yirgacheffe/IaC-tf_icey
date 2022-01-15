#!/bin/bash

# Prepare binary file and launch scripts
BIN_DIR="db-binary"
mkdir ${BIN_DIR}

cp 0*.sql        ${BIN_DIR}
cp mysql_conn.sh ${BIN_DIR}

# Copy to bastion
scp -r ${BIN_DIR} ubuntu@13.212.61.74:~/

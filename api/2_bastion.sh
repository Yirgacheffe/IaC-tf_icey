#!/bin/bash

# Prepare binary file and launch scripts
BIN_DIR="api-binary"

rm -rf ${BIN_DIR}
mkdir  ${BIN_DIR}

cp api-demo-linux ${BIN_DIR}
cp launch.sh      ${BIN_DIR}

# Copy to bastion
scp -r ${BIN_DIR} ubuntu@13.212.61.74:~/

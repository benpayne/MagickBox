#!/bin/bash

GEARMAN=/usr/bin/gearman

echo "Starting gearman for bucket${AETITLE}..."
echo "GEARMAN_JOB_SERVER: ${GEARMAN_JOB_SERVER_NAME}:${GEARMAN_JOB_SERVER_PORT}"
$GEARMAN -h $GEARMAN_JOB_SERVER_NAME -p $GEARMAN_JOB_SERVER_PORT -w -f "bucket${AETITLE}" -- xargs /root/work.sh

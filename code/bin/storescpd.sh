#!/bin/bash
# filename: storescpd
#
# purpose: start storescp server at boot time
# This script is started by monit (/etc/monit/conf.d/processing.conf).
#

tos=5
od=/data/scratch/archive
# create the output directory
#mkdir -p ${od}
#chmod -R 777 ${od}

port=11113
pidfile=/data/.pids/storescpd.pid
# the following script will get the aetitle of the caller, the called aetitle and the path to the data as arguments
#scriptfile=/data/code/bin/inbound_routing.sh
scriptfile=/data/code/bin/receiveSingleFile.sh

case $1 in
    'start')
	echo "Starting storescp daemon..."
	if [ ! -d "$od" ]; then
	    mkdir $od
	fi
	# we should specify a log level here to make this work:
	# 	    --log-config /data/code/bin/logger.cfg
	/usr/bin/storescp \
	    --write-xfer-little \
		-ll debug \
	    --exec-on-eostudy "$scriptfile '#a' '#c' '#r' '#p'" \
		--eostudy-timeout $tos \
  	    --sort-on-study-uid scp \
	    --output-directory "$od" \
	    $port &> /data/logs/storescpd.log &
	pid=$!
	echo $pid > $pidfile
	;;
    'stop')
	/usr/bin/pkill -F $pidfile
	RETVAL=$?
	[ $RETVAL -eq 0 ] && rm -f $pidfile
	;;
    *)
	echo "usage: storescpd { start | stop }"
	;;
esac
exit 0

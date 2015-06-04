#!/bin/bash
#
# create a heart beat for the storescp
# One way it can fail is if multiple associations are requested.
# If the timeout happens the connection will be unusable afterwards.
# Here we simply use echoscu to test the connection and if that
# fails we will kill a running storescp (hoping that monit will start it again).
#
# In order to activate put this into the crontab of processing (every minute)
#   */1 * * * * /usr/bin/nice -n 3 /data/code/bin/heartbeat.sh
#
#

# read in the configuration file
. /data/code/setup.sh
PARENTIP=10.0.2.15
PARENTPORT=1234

log=/data/logs/heartbeat.log

# cheap way to test if storescp is actually running
# check if the storescp log file is new enough
# (Bug: fixes a problem with non-fork send data, echoscu does not work if data is received)
storelog=/data/logs/storescp.log
testtime=5
if [ "$(( $(date +"%s") - $(stat -c "%Y" "$storelog") ))" -lt "$testtime" ]; then
   echo "`date` - no try: storescp.log is too new, seems to work" >> $log
   exit 0
fi

echo "`date` - try now: /usr/bin/echoscu $PARENTIP $PARENTPORT" >> $log
timeout 10 /usr/bin/echoscu $PARENTIP $PARENTPORT
if (($? == 124)); then
   # get pid of the main storescu
   pid=`pgrep -f "storescp.*$PARENTPORT"`
   if [ -z "$pid" ]; then
      echo "storescp's pid could not be found" >> $log
      exit 0
   fi
   echo "`date`: detected unresponsive storescp, kill \"$pid\" and hope that monit restarts it" >> $log
   # stop storescu gracefully first
   kill -s SIGTERM $pid && kill -0 $pid || exit 0
   sleep 5
   # more forceful
   kill -s SIGKILL $pid

   # if we had to kill the process this way they port will belong to a parent, lets kill all of those as well
   portstr=`netstat -lnp | grep $PARENTPORT`
   while [ ! -z "$portstr" ]; do
      echo "the port is still in use..." >> $log
      
      proc=`netstat -lnp | grep $PARENTPORT | cut -d'/' -f2`
      id=`netstat -lnp | grep $PARENTPORT | cut -d'/' -f 1 | awk '{ print $7 }'`
      echo "the port is still in use by a process ($proc) with id $id, kill it" >> $log
      kill $id
      # and check again
      portstr=`netstat -lnp | grep $PARENTPORT`   
   done
fi

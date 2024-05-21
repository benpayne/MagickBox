#!/bin/bash

#
# This script is called if DICOM data is send to the system (for every single file).
#
# Next step from here is that we need to detect if the last file for that study has
# arrived. If that is the case we can start process.sh in bucket01.
#
# Add a cron-job to make sure that we can test for a finished study.
# crontab -e
# */1 * * * * /data/code/bin/detectStudyArrival.sh
# */1 * * * * sleep 15; /data/code/bin/detectStudyArrival.sh
# */1 * * * * sleep 30; /data/code/bin/detectStudyArrival.sh
# */1 * * * * sleep 45; /data/code/bin/detectStudyArrival.sh


if [ $# -eq 0 ]
then
   echo "usage: receiveSingleFile <aetitle caller> <aetitle called> <caller IP> <dicom directory> <DICOM file>"
   exit 1
fi

AETitleCaller=$1
AETitleCalled=$2
CallerIP=$3
DIR=$4
FILE=$5

echo "command: $0" >> /data/logs/receivedSingleFile.log

echo "`date`: Caller: $AETitleCaller, calling $AETitleCalled from $CallerIP in $DIR and file $FILE" >> /data/logs/receivedSingleFile.log
echo "got something for $AETitleCalled" >> /data/logs/receivedSingleFile.log

echo "sending $DIR/$FILE" >> /data/logs/receivedSingleFile.log

# tell the orig2raw script processSingleFile.py that we got a new file
# We can do this using python ... but that will take too much system resources
#    /data/code/bin/processSingleFile.py send "$DIR/$FILE"
# Instead just use bash to write to the named pipe
pipe=/tmp/.processSingleFilePipe
if [[ -p $pipe ]]; then
   # this is a named pipe which will block until someome is reading from it
   echo "$DIR/$FILE" >$pipe
   echo "sent to $AETitleCalled" >> /data/logs/receivedSingleFile.log
fi

# calling inbound routing script to route data to the right bucket
/data/code/bin/inbound_routing.sh $AETitleCaller $AETitleCalled $CallerIP $DIR

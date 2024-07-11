#!/bin/bash

#
# This script is called if DICOM data is send to the system (end of study).
#
if [ $# -eq 0 ]
then
   echo "usage: process.sh <aetitle caller> <aetitle called> <caller IP> <dicom directory>"
   exit 1
fi

# get the PARENTIP and PARENTPORT/WEBPORT variables
. /data/code/setup.sh
echo "`date`: read from setup.sh: $PARENTIP $PARENTPORT" >> /data/logs/bucket01.log


AETitleCaller=`echo $1 | tr -d '"'`
AETitleCalled=`echo $2 | tr -d '"'`
CallerIP=$3
DIR=$4
WORKINGDIR=`mktemp -d --tmpdir=/data/scratch/`
mkdir ${WORKINGDIR}/OUTPUT

echo "`date`: Caller: $AETitleCaller, calling $AETitleCalled from $CallerIP in $DIR" >> /data/logs/bucket01.log
echo "`date`: Process incoming data for processing in $WORKINGDIR" >> /data/logs/bucket01.log

# don't move the data away anymore, keep it in the archive and link to it only (INPUT should not exist here!)
eval /bin/ln -s ${DIR} ${WORKINGDIR}/INPUT

# store the sender information as text
(
cat <<EOF
{
   "CallerIP":"$CallerIP",
   "AETitleCalled":$AETitleCalled,
   "AETitleCaller":$AETitleCaller,
   "received":"`date`"
}
EOF
) > $WORKINGDIR/info.json

echo "`date`: Process bucket01 (processing...)" >> /data/logs/bucket01.log

# check the license
#lic=`/usr/bin/curl "http://mmil.ucsd.edu/MagickBox/queryLicense.php?feature=$AETitleCalled&CallerIP=$CallerIP&AETitleCaller=$AETitleCaller" | cut -d':' -f2 | sed -e 's/[\"})]//g'`
#if [ "$lic" == "-1" ]
#then
#  echo "`date`: Error: no permissions to run this job ($CallerIP requested $AETitleCalled), ignored" >> /data/logs/bucket01.log
#fi
#echo "`date`: can run this job $lic ($CallerIP requested $AETitleCalled)" >> /data/logs/bucket01.log

read s1 < <(date +'%s')
found=0
GEARMAN=`which gearman`
# make sure jq is installed
# make sure that "enabled": 1 is in each active bucket (no double quotes around 1)
buckets=`gearadmin --status | awk '/^bucket/ {print substr($1,7)}'`

for AETitle in $buckets; do
  if [ $AETitleCalled = $AETitle ]; then
    echo "`date`: start stream $AETitle..." >> /data/logs/bucket01.log
    echo "`date`: $WORKINGDIR" >> /data/logs/bucket01.log
    /data/code/magickbox/send_work.py ${AETitle} $WORKINGDIR/INPUT $WORKINGDIR/OUTPUT
    found=1
    break;
  fi
done

if [ "$found" -eq 0 ]; then
  echo "`date`: Error: unknown job type ($CallerIP requested $AETitleCalled), ignored" >> /data/logs/bucket01.log
fi

read s2 < <(date +'%s')
/usr/bin/curl http://${PARENTIP}:${WEBPORT}/code/php/timing.php?aetitle=${AETitleCalled}\&time=$(( s2 - s1 ))

# implement routing
echo "`date`: Process bucket01 (starts routing)..." >> /data/logs/bucket01.log
#/data/code/bin/outbound_routing.py ${WORKINGDIR} $AETitleCalled $AETitleCaller
echo "`date`: Process bucket01 (routing is being performed)..." >> /data/logs/bucket01.log

# implement data extraction
echo "`date`: Start data extraction..." >> /data/logs/bucket01.log
aet=`echo $AETitleCaller | sed -e 's/"//g'`
aec=`echo $AETitleCalled | sed -e 's/"//g'`
/usr/bin/curl -G -d "sender=${aet}&bucket=${aec}&parse=${WORKINGDIR}/OUTPUT" http://${PARENTIP}:${WEBPORT}/code/php/db.php
echo "`date`: End data extraction..." >> /data/logs/bucket01.log

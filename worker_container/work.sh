#!/bin/bash

if [ $# -ne 2 ];
then
   echo "NAME:"
   echo "  work.sh - created by buckets (`date +"%D"`)"
   echo "USAGE:"
   echo ""
   echo "  work.sh <dicom directory> <output directory>"
   echo $1
   exit; 
fi

input=$1
output=$2

# Add the call to your installed program here.
#    ./example_program "\${input}" "\${output}"
# Any result should be copied to \${output}. Don't change/delete anything in \${input}.

echo `ls -l $input` >> /root/log.txt
echo `df -h`  >> /root/log.txt
echo "Processing..."  >> /root/log.txt
/root/extractor.py $input $output  >> /root/log.txt
echo "Done..." >> /root/log.txt
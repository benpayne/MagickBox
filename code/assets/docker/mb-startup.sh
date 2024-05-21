#!/usr/bin/env bash

set +x

# if no arguments are given, start a bash shell
# if the argument is 'start', start the system services and apache
# otherwise, execute the command given as arguments
echo "Starting the system... with $*"
if [ -z "$*" ]; then 
    /usr/bin/env bash; 
else
    if [ "$1" == "start" ]; then
        echo "Start system services and apache...";
        mkdir -p /usr/local/;
        #cron
        #gearmand &
        monit start all &
        apachectl -D FOREGROUND    
    else 
        $*;
    fi
fi

echo "Error log:"
ls -l /var/log/apache2/
cat /var/log/apache2/error.log

#!/bin/bash

nasuser=$1
nashost=$2
workingdir=$3
flagfile=$4

echo "$(date): $0 sending poweroff command to nas host ${nasuser} ${nashost}"

retrycount=5
while [[ $retrycount -ne 0 ]]; do
    ssh -o connecttimeout=5 ${nasuser}@${nashost} shutdown -P now
    if [ $? -eq 0 ]; then
        echo "$(date): $0 sending poweroff command to nas host succeeded"
        retrycount=1
    else
        echo "$(date): $0 sending poweroff command to nas host failed, retry left ${retrycount}"
        sleep 2
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 starting to wait for heartbeat loss ${nashost}"
retrycount=10
while [[ $retrycount -ne 0 ]]; do
    ping -4 -c 3 ${nashost} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "$(date): $0 expecting nas host heartbeat lost succeeded"
        touch ${flagfile}
        retrycount=1
    else
        echo "$(date): $0 waiting for nas host heartbeat loss, retry left ${retrycount}"
        sleep 5
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 completed"

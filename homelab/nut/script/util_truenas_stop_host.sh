#!/bin/sh

nasuser=$1
nashost=$2
workingdir=$3

echo "$(date): $0 sending poweroff command to nas host ${nasuser} ${nashost}"

retrycount=10
while [[ $retrycount -ne 0 ]]; do
    ssh -o connecttimeout=10 ${nasuser}@${nashost} shutdown -P now
    if [ $? -eq 0 ]; then
        echo "$(date): $0 sending poweroff command to nas host succeeded"
        retrycount=1
    else
        echo "$(date): $0 sending poweroff command to nas host failed, retry left ${retrycount}"
        sleep 5
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 starting to wait for heartbeat loss ${nashost}"
retrycount=10
while [[ $retrycount -ne 0 ]]; do
    ping -4 -c 3 ${nashost} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "$(date): $0 heartbeat lost successfully"
        retrycount=1
    else
        echo "$(date): $0 waiting for heartbeat loss..."
        sleep 5
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 completed"

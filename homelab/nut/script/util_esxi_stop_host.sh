#!/bin/bash

esxiuser=$1
esxihost=$2
workingdir=$3

echo "$(date): $0 sending poweroff command to ESXi host ${esxiuser} ${esxihost}"

retrycount=10
while [[ $retrycount -ne 0 ]]; do
    ssh -o connecttimeout=10 ${esxiuser}@${esxihost} poweroff
    if [ $? -eq 0 ]; then
        echo "$(date): $0 sending poweroff command to ESXi host succeeded"
        retrycount=1
    else
        echo "$(date): $0 sending poweroff command to ESXi host failed, retry left ${retrycount}"
        sleep 5
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 starting to wait for heartbeat loss ${esxihost}"
retrycount=10
while [[ $retrycount -ne 0 ]]; do
    ping -4 -c 3 ${esxihost} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "$(date): $0 expecting ESXi host heartbeat lost succeeded"
        retrycount=1
    else
        echo "$(date): $0 waiting for ESXi host heartbeat loss, retry left ${retrycount}"
        sleep 5
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 completed"

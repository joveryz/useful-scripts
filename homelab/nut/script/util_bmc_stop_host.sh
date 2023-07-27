#!/bin/bash

bmcuser=$1
bmchost=$2
workingdir=$3
flagfile=$4
retrycount=10
success="Success"

if [ -f "${flagfile}" ]; then
    echo "$flagfile exists, skip..."
    exit 0
fi

echo "$(date): $0 sending poweroff command to bmc host ${bmchost}"

retrycount=5
while [[ $retrycount -ne 0 ]]; do
    result=$(curl -k -s --location https://oob-${bmchost}/redfish/v1/Systems/1/Actions/ComputerSystem.Reset --header 'Authorization: Basic enRiNTEyOTpPT0IvQ3ludGhpYS8wODA1' --header 'Content-Type: application/json' --data '{"ResetType": "ForceOff"}')
    echo "$(date): $0 ${result}"
    if [[ ${result} =~ ${success} ]]; then
        echo "$(date): $0 sending poweroff command to bmc succeeded"
        retrycount=1
    else
        echo "$(date): $0 sending poweroff command to bmc failed, retry left ${retrycount}"
        sleep 2
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 starting to wait for heartbeat loss ${bmchost}"
retrycount=10
while [[ $retrycount -ne 0 ]]; do
    ping -4 -c 3 ${bmchost} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "$(date): $0 expecting bmc host heartbeat lost succeeded"
        touch ${flagfile}
        retrycount=1
    else
        echo "$(date): $0 waiting for bmc host heartbeat loss, retry left ${retrycount}"
        sleep 5
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 completed"

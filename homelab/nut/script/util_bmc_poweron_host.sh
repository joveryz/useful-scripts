#!/bin/bash

bmcuser=$1
bmchost=$2
workingdir=$3
flagfile=$4
retrycount=10
success="Success"

echo "$(date): $0 sending poweron command to bmc host ${bmchost}"

if [ -f "${flagfile}" ]; then
    echo "$flagfile exists, skip..."
    exit 0
fi

retrycount=5
while [[ $retrycount -ne 0 ]]; do
    result=$(curl -k -s --location https://oob-${bmchost}/redfish/v1/Systems/1/Actions/ComputerSystem.Reset --header 'Authorization: Basic enRiNTEyOTpPT0IvQ3ludGhpYS8wODA1' --header 'Content-Type: application/json' --data '{"ResetType": "On"}')
    echo "$(date): $0 ${result}"
    if [[ ${result} =~ ${success} ]]; then
        echo "$(date): $0 sending poweron command to bmc succeeded"
        retrycount=1
    else
        echo "$(date): $0 sending poweron command to bmc failed, retry left ${retrycount}"
        sleep 2
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 starting to wait for heartbeat ${bmchost}"
retrycount=20
while [[ $retrycount -ne 0 ]]; do
    ping -4 -c 3 ${bmchost} >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$(date): $0 heartbeat got, ping success"
        touch ${flagfile}
        retrycount=1
    else
        echo "$(date): $0 waiting for heartbeat..., retry left ${retrycount}"
        sleep 30
    fi
    retrycount=$((retrycount - 1))
done

echo "$(date): $0 completed"

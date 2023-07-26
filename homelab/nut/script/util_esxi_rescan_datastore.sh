#!/bin/sh

esxiuser=$1
esxihost=$2
workingdir=$3

echo "$(date): $0 rescan datastores on ESXi host ${esxiuser} ${esxihost}"
ssh -o connecttimeout=10 ${esxiuser}@${esxihost} esxcli storage core adapter rescan --all
echo "$(date): $0 completed"

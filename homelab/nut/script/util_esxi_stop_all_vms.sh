#!/bin/sh

esxiuser=$1
esxihost=$2
workingdir=$3

totalvms=0
totalvmsshutdown=0
totalvmspowereddown=0

waitretries=3
waitdelay=10
maxwait=$((waitretries * waitdelay))

dryrun=0
if [ $dryrun -ne 0 ]; then
  waitretries=1
fi

. ${workingdir}/util_esxi_stop_vm.sh

echo "$(date): $0 ${esxiuser}@${esxihost} max wait time=${maxwait}s"
echo "VMs on this esxi host:"
ssh -o connecttimeout=10 "${esxiuser}"@"${esxihost}" vim-cmd vmsvc/getallvms

guestvmids=$(ssh -o connecttimeout=10 "${esxiuser}"@"${esxihost}" vim-cmd vmsvc/getallvms | awk '$1 ~ /^[0-9]+$/ {print $1}')

for guestvmid in $guestvmids; do
  totalvms=$((totalvms + 1))
  shutdown_guest_vm "$guestvmid"
done

echo "--- Total VM count: ${totalvms}"
echo "--- Graceful shutdown count: ${totalvmsshutdown}"
echo "--- Force power off count: ${totalvmspowereddown}"
echo "$(date): $0 completed"

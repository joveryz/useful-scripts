#!/bin/sh

logdir=/etc/nut/log
workingdir="/etc/nut/script"

# Shutdown HomeGen8
esxiuser="root"
esxihost="gen8.sys.ink"
logfile=${logdir}/graceful_shutdown_gen8.log

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to shut down VMs - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_all_vms.sh ${esxiuser} ${esxihost} ${workingdir} >>${logfile}
echo "$(date): Shut down VMs finished - ${esxihost}" >>${logfile}
echo "$(date): Start to shut down host - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_host.sh ${esxiuser} ${esxihost} ${workingdir} >>${logfile}
echo "$(date): Shut down host finished - ${esxihost}" >>${logfile}

# Shutdown HomeGen6
esxiuser="root"
esxihost="gen6.sys.ink"
logfile=${logdir}/graceful_shutdown_gen6.log

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to shut down VMs - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_all_vms.sh ${esxiuser} ${esxihost} ${workingdir} >>${logfile}
echo "$(date): Shut down VMs finished - ${esxihost}" >>${logfile}
echo "$(date): Start to shut down host - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_host.sh ${esxiuser} ${esxihost} ${workingdir} >>${logfile}
echo "$(date): Shut down host finished - ${esxihost}" >>${logfile}

# Shutdown NAS
nsuser="root"
nashost="nas.sys.ink"
logfile=${logdir}/graceful_shutdown_nas.log

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to shut down nas host - ${nashost}" >>${logfile}
${workingdir}/util_truenas_stop_host.sh ${nsuser} ${nashost} ${workingdir} >>${logfile}
echo "$(date): Shut down nas host finished - ${nashost}" >>${logfile}

# Shutdown NUT

nutuser="root"
nuthost="nut.sys.ink"
logfile=${logdir}/graceful_shutdown_nut.log
echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to shut down nut host - ${nuthost}" >>${logfile}
upsmon -c fsd
echo "$(date): Shut down nut host finished - ${nuthost}" >>${logfile}

#!/bin/sh

logdir=/etc/nut/log
workingdir="/etc/nut/script"

# Shutdown HomeGen8
esxiuser="root"
esxihost="gen8.sys.ink"
logfile=${logdir}/graceful_shutdown_gen8.log
flagfile=/tmp/poweroff_flag_gen8

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to shut down VMs - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_all_vms.sh ${esxiuser} ${esxihost} ${workingdir} >>${logfile}
echo "$(date): Shut down VMs finished - ${esxihost}" >>${logfile}
echo "$(date): Start to shut down host - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Shut down host finished - ${esxihost}" >>${logfile}
echo "$(date): Start to shut down bmc - ${esxihost}" >>${logfile}
${workingdir}/util_bmc_stop_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Shut down bmc finished - ${esxihost}" >>${logfile}

# Shutdown HomeGen6
esxiuser="root"
esxihost="gen6.sys.ink"
logfile=${logdir}/graceful_shutdown_gen6.log
flagfile=/tmp/poweroff_flag_gen6

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to shut down VMs - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_all_vms.sh ${esxiuser} ${esxihost} ${workingdir} >>${logfile}
echo "$(date): Shut down VMs finished - ${esxihost}" >>${logfile}
echo "$(date): Start to shut down host - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Shut down host finished - ${esxihost}" >>${logfile}
echo "$(date): Start to shut down bmc - ${esxihost}" >>${logfile}
${workingdir}/util_bmc_stop_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Shut down bmc finished - ${esxihost}" >>${logfile}

# Shutdown NAS
nsuser="root"
nashost="nas.sys.ink"
logfile=${logdir}/graceful_shutdown_nas.log
flagfile=/tmp/poweroff_flag_nas

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to shut down VMs - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_all_vms.sh ${esxiuser} ${esxihost} ${workingdir} >>${logfile}
echo "$(date): Shut down VMs finished - ${esxihost}" >>${logfile}
echo "$(date): Start to shut down host - ${esxihost}" >>${logfile}
${workingdir}/util_esxi_stop_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Shut down host finished - ${esxihost}" >>${logfile}
echo "$(date): Start to shut down bmc - ${esxihost}" >>${logfile}
${workingdir}/util_bmc_stop_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Shut down bmc finished - ${esxihost}" >>${logfile}

# Shutdown NUT

nutuser="root"
nuthost="nut.sys.ink"
logfile=${logdir}/graceful_shutdown_nut.log
echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to shut down nut host - ${nuthost}" >>${logfile}
upsmon -c fsd
echo "$(date): Shut down nut host finished - ${nuthost}" >>${logfile}

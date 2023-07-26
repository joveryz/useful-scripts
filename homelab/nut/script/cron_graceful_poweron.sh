#!/bin/sh

logdir=/etc/nut/log
workingdir="/etc/nut/script"

flagfile=/tmp/poweron_flag_running
if [ -f "${flagfile}" ]; then
    echo "$flagfile exists, skip..."
    exit 0
fi

touch ${flagfile}

# Poweron NAS
nsuser="root"
nashost="nas.sys.ink"
logfile=${logdir}/graceful_poweron_nas.log
flagfile=/tmp/poweron_flag_nas

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to power on nas host - ${nashost}" >>${logfile}
${workingdir}/util_bmc_poweron_host.sh ${nsuser} ${nashost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Power on nas host finished - ${nashost}" >>${logfile}

# Poweron HomeGen6
esxiuser="root"
esxihost="gen6.sys.ink"
logfile=${logdir}/graceful_poweron_gen6.log
flagfile=/tmp/poweron_flag_gen6

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to power on esxi host - ${esxihost}" >>${logfile}
${workingdir}/util_bmc_poweron_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Power on esxi host finished - ${esxihost}" >>${logfile}

# Poweron HomeGen8
esxiuser="root"
esxihost="gen8.sys.ink"
logfile=${logdir}/graceful_poweron_gen8.log
flagfile=/tmp/poweron_flag_gen8

echo "--------------------------------------------------------" >> ${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to power on esxi host - ${esxihost}" >> ${logfile}
${workingdir}/util_bmc_poweron_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Power on esxi host finished - ${esxihost}" >> ${logfile}

flagfile=/tmp/poweron_flag_running
/bin/rm -f ${flagfile}

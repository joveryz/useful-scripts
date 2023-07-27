#!/bin/sh

logdir=/etc/nut/log
workingdir="/etc/nut/script"
logfile=${logdir}/graceful_poweron_$(date '+%Y_%m_%d_%H_%M_%S_%s').log

runflagfile=/tmp/poweron_flag_running
if [ -f "${flagfile}" ]; then
    echo "$flagfile exists, skip..."
    exit 0
fi

touch ${runflagfile}

# Poweron NAS
nsuser="root"
nashost="nas.sys.ink"
flagfile=/tmp/poweron_flag_nas

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to power on nas host - ${nashost}" >>${logfile}
${workingdir}/util_bmc_poweron_host.sh ${nsuser} ${nashost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Power on nas host finished - ${nashost}" >>${logfile}

if [ ! -f "${flagfile}" ]; then
    echo "Power on nas failed because $flagfile not exists, skip..." >>${logfile}
    /bin/rm -f ${runflagfile}
    exit 0
fi

# Poweron HomeGen6
esxiuser="root"
esxihost="gen6.sys.ink"
flagfile=/tmp/poweron_flag_gen6

echo "--------------------------------------------------------" >>${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to power on esxi host - ${esxihost}" >>${logfile}
${workingdir}/util_bmc_poweron_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Power on esxi host finished - ${esxihost}" >>${logfile}

# Poweron HomeGen8
esxiuser="root"
esxihost="gen8.sys.ink"
flagfile=/tmp/poweron_flag_gen8

echo "--------------------------------------------------------" >> ${logfile}
echo "$(date): This is $(whoami) serving for you" >>${logfile}
echo "$(date): Start to power on esxi host - ${esxihost}" >> ${logfile}
${workingdir}/util_bmc_poweron_host.sh ${esxiuser} ${esxihost} ${workingdir} ${flagfile} >>${logfile}
echo "$(date): Power on esxi host finished - ${esxihost}" >> ${logfile}

/bin/rm -f ${runflagfile}

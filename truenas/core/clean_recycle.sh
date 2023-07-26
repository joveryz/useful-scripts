#!/bin/sh

logdir=/mnt/systempool/log/recycle
logfile=${logdir}/clean_recycle.log

echo "--------------------------------------------------------" >> ${logfile}
echo "$(date): Clean all recycle bins" >> ${logfile}
find /mnt/systempool/*/.recycle/* -print -delete >> ${logfile}
find /mnt/systempool/*/.recycle/ -type d -empty -print -delete >> ${logfile}
find /mnt/datapool/*/.recycle/* -print -delete >> ${logfile}
find /mnt/datapool/*/.recycle/ -type d -empty -print -delete >> ${logfile}
find /mnt/servicepool/*/.recycle/* -print -delete >> ${logfile}
find /mnt/servicepool/*/.recycle/ -type d -empty -print -delete >> ${logfile}

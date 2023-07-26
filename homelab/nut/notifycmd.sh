#!/bin/bash

logdir=/etc/nut/log
logfile=${logdir}/nut.log
uuid=$(cat /proc/sys/kernel/random/uuid)
emailcontent=/tmp/email_content_${uuid}.tmp
emailto='ztb5129@qq.com'

(
    echo "Subject: [RPI-NUT] ALERT: ${NOTIFYTYPE}"
    echo "-------------------------------------------------"
) >>${emailcontent}

case ${NOTIFYTYPE} in
ONLINE)
    /bin/rm -f /tmp/nut_flag_onbatt
    /bin/rm -f /tmp/nut_flag_lowbatt
    (
        echo "The UPS has recovered..."
    ) >>${emailcontent}
    ;;
ONBATT)
    (
        echo "The UPS has been on battery..."
    ) >>${emailcontent}
    touch /tmp/nut_flag_onbatt
    ;;
LOWBATT)
    (
        echo "The UPS has been on low battery..."
        echo "Start graceful shutdown sequence..."
        /bin/sh /etc/nut/script/nut_graceful_shutdown.sh &
    ) >>${emailcontent}
    touch /tmp/nut_flag_lowbatt
    ;;
*)
    (
        echo "No extra info provided..."
    ) >>${emailcontent}
    ;;
esac

(
    echo "-------------------------------------------------"
    echo "UPS: ${UPSNAME}"
    echo "-------------------------------------------------"
    upsc ups@localhost
) >>${emailcontent}
cat ${emailcontent} | msmtp ${emailto}
/bin/rm -f ${emailcontent}

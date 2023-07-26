#!/bin/bash

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${SCRIPT_PATH}/report_status.conf"
source "${SCRIPT_PATH}/util_format_email.sh"

bash ${SCRIPT_PATH}/util_report_smart.sh
bash ${SCRIPT_PATH}/util_report_zpool.sh
bash ${SCRIPT_PATH}/util_report_ups.sh

info_level="INFO"
if grep -q "ERROR" "${EMAIL_INFO_LEVEL}"; then
  info_level="ERROR"
elif grep -q "WARN" "${EMAIL_INFO_LEVEL}"; then
  info_level="WARN"
fi

cat ${EMAIL_INFO_LEVEL} >> ${EMAIL_ALL}
cat ${EMAIL_SUMMARY} >> ${EMAIL_ALL}
cat ${EMAIL_BODY} >> ${EMAIL_ALL}

EMAIL_SUBJECT="[NAS.SYS.INK] [INFOLEVEL] Status Report"
EMAIL_SUBJECT="$(echo ${EMAIL_SUBJECT} | sed "s/INFOLEVEL/${info_level}/")"
format_email "${EMAIL_SUBJECT}" "${EMAIL_ADDRESS}" "${EMAIL_ALL}" | sendmail -i -t

rm ${EMAIL_INFO_LEVEL}
rm ${EMAIL_SUMMARY}
rm ${EMAIL_BODY}
rm ${EMAIL_BODY}.bak
rm ${EMAIL_ALL}

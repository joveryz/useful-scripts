#!/usr/bin/env bash
#
# Send a SMART status summary and detailed report of all SATA drives via Email.

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=report_status.conf
source "${SCRIPT_PATH}/report_status.conf"

# Only specify monospace font to let Email client decide of the rest.
echo "<pre style=\"font-family:monospace\">" >> "${EMAIL_SUMMARY}"

# Print a summary table of the status of all drives.
(
  echo "<b>SMART status report summary for all drives:</b>"
  echo "+-----------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+----+"
  echo "|Device     |Serial         |Temp|Power|Power|Spin |ReAlloc|Current|Offline |UDMA  |Seek  |Last|"
  echo "|           |               |    |On   |Cycle|Retry|Sectors|Pending|Uncorrec|CRC   |Errors|Test|"
  echo "|           |               |    |Hours|Count|Count|       |Sectors|Sectors |Errors|      |Age |"
  echo "+-----------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+----+"
) >> "${EMAIL_SUMMARY}"

info_level="INFO"
for drive_label in ${SATA_DRIVES}; do
  # Ask smartctl to diplay the Seek_Error_Rate in raw hexadecimal so that we can extract the number of seek errors and
  # total number of seeks afterwards.
  drive_status="$(smartctl -A -i -v 7,hex48 /dev/"${drive_label}")"
  drive_tests_list="$(smartctl -l selftest /dev/"${drive_label}")"

  last_test_hours="$(echo "${drive_tests_list}" | grep "# 1" | awk '{print $9}')"
  serial_number="$(echo "${drive_status}" | grep "Serial Number:" | awk '{print $3}')"
  temperature="$(echo "${drive_status}" | grep "Temperature_Celsius" | awk '{print $10}')" # SATA HDD
  if [[ -z "${temperature}" ]]; then
    temperature="$(echo "${drive_status}" | grep "Airflow_Temperature_Cel" | awk '{print $10}')" # SATA SSD
  fi
  power_on_hours="$(echo "${drive_status}" | grep "Power_On_Hours" | awk '{print $10}')"
  if [[ ! (${power_on_hours} =~ ^[0-9]+$) ]]; then
    power_on_hours="$(echo "${power_on_hours}" | awk -F"+" '{print $1}' | sed 's/[^0-9]*//g')"
  fi
  power_cycle_count="$(echo "${drive_status}" | grep "Power_Cycle_Count" | awk '{print $10}')"
  spin_retry_count="$(echo "${drive_status}" | grep "Spin_Retry_Count" | awk '{print $10}')"
  realocated_sectors="$(echo "${drive_status}" | grep "Reallocated_Sector" | awk '{print $10}')"
  pending_sectors_count="$(echo "${drive_status}" | grep "Current_Pending_Sector" | awk '{print $10}')"
  uncorrectable_sectors_count="$(echo "${drive_status}" | grep "Offline_Uncorrectable" | awk '{print $10}')"
  udma_crc_errors_count="$(echo "${drive_status}" | grep "UDMA_CRC_Error_Count" | awk '{print $10}')"
  # Using cut to grab the first 4 hex symbols which indicate the actual number of seek errors.
  seek_errors="$(echo "${drive_status}" | grep "Seek_Error_Rate" | awk '{print $10}' | cut -c 1-6)"
  # Using cut to grab the last 8 hex symbols which indicate the total number of seeks.
  total_seeks="$(echo "${drive_status}" | grep "Seek_Error_Rate" | awk '{print $10}' | cut -c 1-2,7-14)"
  command_timeout="$(echo "${drive_status}" | grep "Command_Timeout" | awk '{print $10}')"

  # Force LC_NUMERIC because on certain non en_US systems the decimal separator is a comma and we need a dot.
  # printf "%.0f" in order to round the resulting number.
  # Bash doesn't "natively" support float numbers so bc is used to have a float result to a division.
  test_age="$(awk -- 'BEGIN{printf "%.0f\n", (ARGV[1]-ARGV[2])/24}' "${power_on_hours}" "${last_test_hours}")"

  # Choose the symbol to display beside the drive name.
  if [[ "${temperature}" -ge "${DRIVE_TEMPERATURE_CRITICAL}" ]] ||
    [[ "${realocated_sectors}" -gt "${DRIVE_SECTORS_CRITICAL}" ]] ||
    [[ "${pending_sectors_count}" -gt "${DRIVE_SECTORS_CRITICAL}" ]] ||
    [[ "${uncorrectable_sectors_count}" -gt "${DRIVE_SECTORS_CRITICAL}" ]]; then
    drive_symbol="${UI_CRITICAL_SYMBOL}"
    info_level="<font color=\"#FF0000\"> ERROR </font>"
  elif [[ "${temperature}" -ge "${DRIVE_TEMPERATURE_WARNING}" ]] ||
    [[ "${realocated_sectors}" -gt "0" ]] ||
    [[ "${pending_sectors_count}" -gt "0" ]] ||
    [[ "${uncorrectable_sectors_count}" -gt "0" ]] ||
    [[ "${test_age}" -ge "${SMART_TEST_AGE_WARNING}" ]]; then
    drive_symbol="${UI_WARNING_SYMBOL}"
    info_level="<font color=\"#FF0000\"> WARN </font>"
  else
    drive_symbol=" "
  fi

  if [[ "${temperature}" -ge "${DRIVE_TEMPERATURE_CRITICAL}" ]]; then
    ui_symbol="${UI_CRITICAL_SYMBOL}"
  elif [[ "${temperature}" -ge "${DRIVE_TEMPERATURE_WARNING}" ]]; then
    ui_symbol="${UI_WARNING_SYMBOL}"
  else
    ui_symbol=" "
  fi
  temperature=${ui_symbol}${temperature}

  if [[ "${realocated_sectors}" -gt "${DRIVE_SECTORS_CRITICAL}" ]]; then
    ui_symbol="${UI_CRITICAL_SYMBOL}"
  elif [[ "${realocated_sectors}" -gt "0" ]]; then
    ui_symbol="${UI_WARNING_SYMBOL}"
  else
    ui_symbol=" "
  fi
  realocated_sectors=${ui_symbol}${realocated_sectors}

  if [[ "${pending_sectors_count}" -gt "${DRIVE_SECTORS_CRITICAL}" ]]; then
    ui_symbol="${UI_CRITICAL_SYMBOL}"
  elif [[ "${pending_sectors_count}" -gt "0" ]]; then
    ui_symbol="${UI_WARNING_SYMBOL}"
  else
    ui_symbol=" "
  fi
  pending_sectors_count=${ui_symbol}${pending_sectors_count}

  if [[ "${uncorrectable_sectors_count}" -gt "${DRIVE_SECTORS_CRITICAL}" ]]; then
    ui_symbol="${UI_CRITICAL_SYMBOL}"
  elif [[ "${uncorrectable_sectors_count}" -gt "0" ]]; then
    ui_symbol="${UI_WARNING_SYMBOL}"
  else
    ui_symbol=" "
  fi
  uncorrectable_sectors_count=${ui_symbol}${uncorrectable_sectors_count}

  if [[ "${test_age}" -gt "${SMART_TEST_AGE_WARNING}" ]]; then
    ui_symbol="${UI_WARNING_SYMBOL}"
  else
    ui_symbol=" "
  fi
  test_age=${ui_symbol}${test_age}

  # seek_errors and total_seeks are stored as hex values, we need to convert them before comparing and displaying.
  seek_errors="$(printf "%d" "${seek_errors}")"
  total_seeks="$(printf "%d" "${total_seeks}")"

  if [[ -z "${spin_retry_count// }" ]]; then
    spin_retry_count="N/A"
  fi
  if [[ -z "${pending_sectors_count// }" ]]; then
    pending_sectors_count="N/A"
  fi
  if [[ -z "${uncorrectable_sectors_count// }" ]]; then
    uncorrectable_sectors_count="N/A"
  fi

  # Print the row with all the attributes corresponding to the drive.
  printf "|%-9s %1s|%-15s| %s|%5s|%5s|%5s|%7s|%7s|%8s|%6s|%6s|%4s|\n" "${drive_label}" "${drive_symbol}" \
    "${serial_number: -8}" "${temperature}" "${power_on_hours}" "${power_cycle_count}" "${spin_retry_count}" \
    "${realocated_sectors}" "${pending_sectors_count}" "${uncorrectable_sectors_count}" "${udma_crc_errors_count}" \
    "${seek_errors}" "${test_age}" >> "${EMAIL_SUMMARY}"
done
echo "+-----------+---------------+----+-----+-----+-----+-------+-------+--------+------+------+----+" >> "${EMAIL_SUMMARY}"
echo "</pre>" >> "${EMAIL_SUMMARY}"

echo "<pre style=\"font-family:monospace\">" >> "${EMAIL_BODY}"
# Print a detailed SMART report for each drive.
for drive_label in ${SATA_DRIVES}; do
  drive_smart_info="$(smartctl -i /dev/"${drive_label}")"
  brand="$(echo "${drive_smart_info}" | grep "Device Model" | awk '{print $3, $4, $5}')"
  serial_number="$(echo "${drive_smart_info}" | grep "Serial Number" | awk '{print $3}')"
  (
    echo ""
    echo ""
    echo "<b>SMART status report for ${drive_label} drive (${brand}: ${serial_number}):</b>"
    # Dislpay the SMART status table.
    smartctl -H -A -l error /dev/"${drive_label}" | awk 'NF'
    # Display the status of the last selftest.
    smartctl -l selftest /dev/"${drive_label}" | grep "# 1 \|Num" | cut -c6- | awk 'NF'
  ) >> "${EMAIL_BODY}"
done

# Trimming unnecessary information from SMART detailed reports.
sed -i.bak -e '/smartctl 6.3/d' "${EMAIL_BODY}"
sed -i.bak -e '/Copyright/d' "${EMAIL_BODY}"
sed -i.bak -e '/=== START OF READ/d' "${EMAIL_BODY}"
sed -i.bak -e '/SMART Attributes Data/d' "${EMAIL_BODY}"
sed -i.bak -e '/Vendor Specific SMART/d' "${EMAIL_BODY}"
sed -i.bak -e '/SMART Error Log Version/d' "${EMAIL_BODY}"
sed -i.bak -e '/smartctl 7.2/d' "${EMAIL_BODY}"

echo "</pre>" >> "${EMAIL_BODY}"

echo "<pre style=\"font-family:monospace\">" >> "${EMAIL_INFO_LEVEL}"
echo "<b>SMART Overall Status: ${info_level}</b>" >> "${EMAIL_INFO_LEVEL}"
echo "</pre>" >> "${EMAIL_INFO_LEVEL}"

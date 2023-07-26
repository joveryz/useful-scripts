#!/usr/bin/env bash
#
# Send a UPS status summary via Email.

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=report_status.conf
source "${SCRIPT_PATH}/report_status.conf"

# Only specify monospace font to let Email client decide of the rest.
echo "<pre style=\"font-family:monospace\">" >> "${EMAIL_SUMMARY}"

# Print a summary table of the status of all UPS.
(
  echo "<b>UPS status report summary for all UPS:</b>"
  echo "+--------------+------+-----+------+-------+-------+-------+-------+----------+----------+"
  echo "|Device        |Status|Load |Real  |Battery|Battery|Battery|Battery|Battery   |Last      |"
  echo "|              |      |     |Power |Charge |Voltage|Temp   |Runtime|Change    |Test      |"
  echo "|              |      |     |Output|       |       |       |       |Date      |Date      |"
  echo "+--------------+------+-----+------+-------+-------+-------+-------+----------+----------+"
) >> "${EMAIL_SUMMARY}"
for ups in ${UPS_LIST}; do
  upsc="upsc ${ups}@nut.sys.ink"

  # Here I can't use someting like real_power="$(upsc "${ups}" ups.realpower)"; real_power="${real_power:-N/A}" because
  # if I want to display units in the table row (with printf |%3s W| for example) I will end up with "N/A W" if the
  # 'realpower' variable isn't supported by the UPS.
  if [[ -n "$(${upsc} ups.status 2>/dev/null)" ]]; then
    status="$(${upsc} ups.status 2>/dev/null)"
  else
    status="N/A"
  fi
  if [[ -n "$(${upsc} ups.load 2>/dev/null)" ]]; then
    load="$(${upsc} ups.load 2>/dev/null) %"
  else
    load="N/A"
  fi
  if [[ -n "$(${upsc} ups.realpower 2>/dev/null)" ]]; then
    real_power="$(${upsc} ups.realpower 2>/dev/null) W"
  else
    real_power="N/A"
  fi
  if [[ -n "$(${upsc} battery.charge 2>/dev/null)" ]]; then
    battery_charge="$(${upsc} battery.charge 2>/dev/null) %"
  else
    battery_charge="N/A"
  fi
  if [[ -n "$(${upsc} battery.voltage 2>/dev/null)" ]]; then
    battery_voltage="$(${upsc} battery.voltage 2>/dev/null) V"
  else
    battery_voltage="N/A"
  fi
  if [[ -n "$(${upsc} battery.temperature 2>/dev/null)" ]]; then
    battery_temperature="$(${upsc} battery.temperature 2>/dev/null) °C"
  else
    battery_temperature="N/A"
  fi
  if [[ -n "$(${upsc} battery.runtime 2>/dev/null)" ]]; then
    battery_runtime="$(${upsc} battery.runtime 2>/dev/null) s"
  else
    battery_runtime="N/A"
  fi
  if [[ -n "$(${upsc} battery.date 2>/dev/null)" ]]; then
    battery_change_date="$(${upsc} battery.date 2>/dev/null)"
  else
    battery_change_date="N/A"
  fi
  if [[ -n "$(${upsc} ups.test.date 2>/dev/null)" ]]; then
    last_test_date="$(${upsc} ups.test.date 2>/dev/null)"
  else
    last_test_date="N/A"
  fi

  printf "|%-14s|%6s|%5s|%6s|%7s|%7s|%7s|%7s|%10s|%10s|\n" "${ups}" "${status}" "${load}" "${real_power}" \
    "${battery_charge}" "${battery_voltage}" "${battery_temperature}" "${battery_runtime}" "${battery_change_date}" \
    "${last_test_date}" >> "${EMAIL_SUMMARY}"
done
echo "+--------------+------+-----+------+-------+-------+-------+-------+----------+----------+" >> "${EMAIL_SUMMARY}"
echo "</pre>" >> "${EMAIL_SUMMARY}"

echo "<pre style=\"font-family:monospace\">" >> "${EMAIL_BODY}"
# Print a detailed UPS report for each UPS.
for ups in ${UPS_LIST}; do
  upsc="upsc ${ups}@nut.sys.ink"
  (
    echo ""
    echo ""
    echo "<b>UPS status report for ${ups} UPS ($(${upsc} device.mfr 2>/dev/null) $(${upsc} device.model 2>/dev/null | sed -e 's/[[:space:]]*$//'): $(${upsc} device.serial 2>/dev/null)):</b>"
    if [[ -n "$(${upsc} ups.firmware 2>/dev/null)" ]]; then
      echo "Firmware version: $(${upsc} ups.firmware 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} battery.date 2>/dev/null)" ]]; then
      echo "Battery Change Date: $(${upsc} battery.date 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} battery.mfr.date 2>/dev/null)" ]]; then
      echo "Battery Manufacturing Date: $(${upsc} battery.mfr.date 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} ups.test.result 2>/dev/null)" ]]; then
      echo "Last Self-Test Result: $(${upsc} ups.test.result 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} ups.test.date 2>/dev/null)" ]]; then
      echo "Last Self-Test Date: $(${upsc} ups.test.date 2>/dev/null)"
    fi
    echo ""
    if [[ -n "$(${upsc} device.uptime 2>/dev/null)" ]]; then
      echo "Uptime: $(${upsc} device.uptime 2>/dev/null) s"
    fi
    if [[ -n "$(${upsc} ups.status 2>/dev/null 2>/dev/null)" ]]; then
      echo "Status: $(${upsc} ups.status 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} ups.temperature 2>/dev/null)" ]]; then
      echo "Temperature: $(${upsc} ups.temperature 2>/dev/null) °C"
    fi
    if [[ -n "$(${upsc} ups.load 2>/dev/null)" ]]; then
      echo "Load: $(${upsc} ups.load 2>/dev/null) %"
    fi
    if [[ -n "$(${upsc} ups.efficiency 2>/dev/null)" ]]; then
      echo "Efficiency: $(${upsc} ups.efficiency 2>/dev/null) %"
    fi
    echo ""
    if [[ -n "$(${upsc} input.voltage 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} input.voltage.nominal 2>/dev/null)" ]]; then
        echo "Input Voltage: $(${upsc} input.voltage 2>/dev/null) V ($(${upsc} input.voltage.nominal 2>/dev/null) V nominal)"
      else
        echo "Input Voltage: $(${upsc} input.voltage 2>/dev/null) V"
      fi
    fi
    if [[ -n "$(${upsc} input.current 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} input.current.nominal 2>/dev/null)" ]]; then
        echo "Input Current: $(${upsc} input.current 2>/dev/null) A ($(${upsc} input.current.nominal 2>/dev/null) A nominal)"
      else
        echo "Input Current: $(${upsc} input.current 2>/dev/null) A"
      fi
    fi
    if [[ -n "$(${upsc} input.frequency 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} input.frequency.nominal 2>/dev/null)" ]]; then
        echo "Input Frequency: $(${upsc} input.frequency 2>/dev/null) Hz ($(${upsc} input.frequency.nominal 2>/dev/null) Hz nominal)"
      else
        echo "Input Frequency: $(${upsc} input.frequency 2>/dev/null) Hz"
      fi
    fi
    if [[ -n "$(${upsc} input.power 2>/dev/null)" ]]; then
      echo "Input Apparent Power: $(${upsc} input.power 2>/dev/null) VA"
    fi
    if [[ -n "$(${upsc} input.realpower 2>/dev/null)" ]]; then
      echo "Input Real Power: $(${upsc} input.realpower 2>/dev/null) W"
    fi
    echo ""
    if [[ -n "$(${upsc} output.voltage 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} output.voltage.nominal 2>/dev/null)" ]]; then
        echo "Output Voltage: $(${upsc} output.voltage 2>/dev/null) V ($(${upsc} output.voltage.nominal 2>/dev/null) V nominal)"
      else
        echo "Output Voltage: $(${upsc} output.voltage 2>/dev/null) V"
      fi
    fi
    if [[ -n "$(${upsc} output.current 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} output.current.nominal 2>/dev/null)" ]]; then
        echo "Output Current: $(${upsc} output.current 2>/dev/null) A ($(${upsc} output.current.nominal 2>/dev/null) A nominal)"
      else
        echo "Output Current: $(${upsc} output.current 2>/dev/null) A"
      fi
    fi
    if [[ -n "$(${upsc} output.frequency 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} output.frequency.nominal 2>/dev/null)" ]]; then
        echo "Output Frequency: $(${upsc} output.frequency 2>/dev/null) Hz ($(${upsc} output.frequency.nominal 2>/dev/null) Hz nominal)"
      else
        echo "Output Frequency: $(${upsc} output.frequency 2>/dev/null) Hz"
      fi
    fi
    if [[ -n "$(${upsc} ups.power 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} ups.power.nominal 2>/dev/null)" ]]; then
        echo "Output Apparent Power: $(${upsc} ups.power 2>/dev/null) VA ($(${upsc} ups.power.nominal 2>/dev/null) VA nominal)"
      else
        echo "Output Apparent Power: $(${upsc} ups.power 2>/dev/null) VA"
      fi
    fi
    if [[ -n "$(${upsc} ups.realpower 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} ups.realpower.nominal 2>/dev/null)" ]]; then
        echo "Output Real Power: $(${upsc} ups.realpower 2>/dev/null) W ($(${upsc} ups.realpower.nominal 2>/dev/null) W nominal)"
      else
        echo "Output Real Power: $(${upsc} ups.realpower 2>/dev/null) W"
      fi
    fi
    echo ""
    if [[ -n "$(${upsc} battery.charge 2>/dev/null)" ]]; then
      echo "Battery Charge: $(${upsc} battery.charge 2>/dev/null) %"
    fi
    if [[ -n "$(${upsc} battery.voltage 2>/dev/null)" ]]; then
      if [[ -n "$(${upsc} battery.voltage.nominal 2>/dev/null)" ]]; then
        echo "Battery Voltage: $(${upsc} battery.voltage 2>/dev/null) V ($(${upsc} battery.voltage.nominal 2>/dev/null) V nominal)"
      else
        echo "Battery Voltage: $(${upsc} battery.voltage 2>/dev/null) V"
      fi
    fi
    if [[ -n "$(${upsc} battery.current 2>/dev/null)" ]]; then
      echo "Battery Current: $(${upsc} battery.current 2>/dev/null) A"
    fi
    if [[ -n "$(${upsc} battery.capacity 2>/dev/null)" ]]; then
      echo "Battery Capacity: $(${upsc} battery.capacity 2>/dev/null) Ah"
    fi
    if [[ -n "$(${upsc} battery.temperature 2>/dev/null)" ]]; then
      echo "Battery Temperature: $(${upsc} battery.temperature 2>/dev/null) °C"
    fi
    if [[ -n "$(${upsc} battery.runtime 2>/dev/null)" ]]; then
      echo "Battery Runtime: $(${upsc} battery.runtime 2>/dev/null) s"
    fi
    if [[ -n "$(${upsc} battery.type 2>/dev/null)" ]]; then
      echo "Battery Type: $(${upsc} battery.type 2>/dev/null)"
    fi
    echo ""
    if [[ -n "$(${upsc} ups.beeper.status 2>/dev/null)" ]]; then
      echo "Beeper Status: $(${upsc} ups.beeper.status 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} ups.watchdog.status 2>/dev/null)" ]]; then
      echo "Watchdog Status: $(${upsc} ups.watchdog.status 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} ups.delay.shutdown 2>/dev/null)" ]]; then
      echo "Shutdown Delay: $(${upsc} ups.delay.shutdown 2>/dev/null) s"
    fi
    if [[ -n "$(${upsc} ups.delay.reboot 2>/dev/null)" ]]; then
      echo "Reboot Delay: $(${upsc} ups.delay.reboot 2>/dev/null) s"
    fi
    if [[ -n "$(${upsc} ups.delay.start 2>/dev/null)" ]]; then
      echo "Start Delay: $(${upsc} ups.delay.start 2>/dev/null) s"
    fi
    if [[ -n "$(${upsc} ups.timer.shutdown 2>/dev/null)" ]]; then
      echo "Shutdown Timer: $(${upsc} ups.timer.shutdown 2>/dev/null) s"
    fi
    if [[ -n "$(${upsc} ups.timer.reboot 2>/dev/null)" ]]; then
      echo "Reboot Timer: $(${upsc} ups.timer.reboot 2>/dev/null) s"
    fi
    if [[ -n "$(${upsc} ups.timer.start 2>/dev/null)" ]]; then
      echo "Start Timer: $(${upsc} ups.timer.start 2>/dev/null) s"
    fi
    if [[ -n "$(${upsc} ups.start.auto 2>/dev/null)" ]]; then
      echo "Auto Start: $(${upsc} ups.start.auto 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} ups.start.battery 2>/dev/null)" ]]; then
      echo "Start From Battery: $(${upsc} ups.start.battery 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} ups.start.reboot 2>/dev/null)" ]]; then
      echo "Cold Start From Battery: $(${upsc} ups.start.reboot 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} ups.shutdown 2>/dev/null)" ]]; then
      echo "Shutdown Ability: $(${upsc} ups.shutdown 2>/dev/null)"
    fi
    if [[ -n "$(${upsc} ups.test.interval 2>/dev/null)" ]]; then
      echo "Self-Test Interval: $(${upsc} ups.test.interval 2>/dev/null) s"
    fi
  ) >> "${EMAIL_BODY}"
done

echo "</pre>" >> "${EMAIL_BODY}"

echo "<pre style=\"font-family:monospace\">" >> "${EMAIL_INFO_LEVEL}"
echo "<b>UPS Overall Status: INFO</b>" >> "${EMAIL_INFO_LEVEL}"
echo "</pre>" >> "${EMAIL_INFO_LEVEL}"

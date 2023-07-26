#!/bin/sh

shutdown_guest_vm() {
  l_try=0

  ssh -o connecttimeout=10 "${esxiuser}"@"${esxihost}" vim-cmd vmsvc/power.getstate $1 | grep -i "off" >/dev/null 2<&1
  l_status=$?

  # printf "VM [%s] status=[%s]\n" "$1" "${l_status}"

  if [ $l_status -eq 0 ]; then
    echo "VM ID $1 already powered down, skip..."
  else
    while [ $l_try -lt $waitretries ] && [ $l_status -ne 0 ]; do
      l_try=$((l_try + 1))
      if [ $dryrun -ne 0 ]; then
        echo "TEST MODE: Would issue shutdown command and wait ${waitdelay} seconds for VM ID $1 to shutdown (attempt $l_try of $waitretries)..."
      else
        ssh -o connecttimeout=10 "${esxiuser}"@"${esxihost}" vim-cmd vmsvc/power.shutdown $1 >/dev/null 2<&1
        echo "Waiting ${waitdelay} seconds for VM ID $1 to shutdown (attempt $l_try of $waitretries)..."
        sleep $waitdelay
        ssh -o connecttimeout=10 "${esxiuser}"@"${esxihost}" vim-cmd vmsvc/power.getstate $1 | grep -i "off" >/dev/null 2<&1
        l_status=$?
        #	      printf "VM [%s] status=[%s] try=[%s]\n" "$1" "${l_status}" "${l_try}"
      fi
    done
    if [ $l_status -eq 0 ]; then
      echo "Shut down sucessful on attempt ${l_try}..."
      totalvmsshutdown=$((totalvmsshutdown + 1))
    else
      if [ $dryrun -ne 0 ]; then
        echo "TEST MODE: Unable to gracefully shutdown VM ID $1, would force power off and wait ${waitdelay} seconds before checking status."
      else
        echo "Unable to gracefully shut down VM ID $1, forcing power off..."
        ssh -o connecttimeout=10 "${esxiuser}"@"${esxihost}" vim-cmd vmsvc/power.off $1 >/dev/null 2<&1
        sleep $waitdelay
      fi
      ssh -o connecttimeout=10 "${esxiuser}"@"${esxihost}" vim-cmd vmsvc/power.getstate $1 | grep -i "off" >/dev/null 2<&1
      l_status=$?
      #     printf "VM [%s] status=[%s]\n" "$1" "${l_status}"
      if [ $l_status -eq 0 ]; then
        totalvmspowereddown=$((totalvmspowereddown + 1))
      fi
    fi
  fi
}

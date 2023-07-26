###### User-definable Parameters
### Email Address
toemail="ztb5129@qq.com"

### TrueNAS config backup settings
configBackup="true"     # Change to "false" to skip config backup (which renders next two options meaningless); "true" to keep config backups enabled
saveBackup="true"       # Change to "false" to delete TrueNAS config backup after mail is sent; "true" to keep it in dir below
backupLocation="/mnt/servicepool/service/configs"   # Directory in which to save TrueNAS config backups

###### Auto-generated Parameters
logfile="/tmp/backup_config_email_body.tmp"
subject="[NAS.SYS.INK] Configuration Backup"

###### Email pre-formatting
### Set email headers
(
    echo "MIME-Version: 1.0"
    echo "Subject: ${subject}"
    echo "To: ${toemail}"
    echo "Content-Type: multipart/mixed; boundary=${boundary}"
) > "$logfile"


###### Config backup (if enabled)
if [ "$configBackup" == "true" ]; then
    # Set up file names, etc for later
    tarfile="/tmp/config_backup.tar.gz"
    filename="$(date "+TrueNAS_Config_%Y-%m-%d")"
    ### Test config integrity
    if ! [ "$(sqlite3 /data/freenas-v1.db "pragma integrity_check;")" == "ok" ]; then
        # Config integrity check failed, set MIME content type to html and print warning
        (
            echo "--${boundary}"
            echo "Content-Type: text/html"
            echo "Automatic backup of TrueNAS configuration has failed! The configuration file is corrupted!"
            echo "<br>"
            echo "You should correct this problem as soon as possible!"
        ) >> "$logfile"
    else
        # Config integrity check passed; copy config db, generate checksums, make .tar.gz archive
        cp /data/freenas-v1.db "/tmp/${filename}.db"
        md5sum "/tmp/${filename}.db" > /tmp/config_backup.md5
        sha256sum "/tmp/${filename}.db" > /tmp/config_backup.sha256
        (
            cd "/tmp/" || exit;
            tar -czf "${tarfile}" "./${filename}.db" ./config_backup.md5 ./config_backup.sha256;
        )
        (
            # Write MIME section header for file attachment (encoded with base64)
            echo "--${boundary}"
            echo "Content-Type: application/tar+gzip"
            echo "Content-Transfer-Encoding: base64"
            echo "Content-Disposition: attachment; filename=${filename}.tar.gz"
            base64 "$tarfile"
            # Write MIME section header for html content to come below
            echo "--${boundary}"
            echo "Content-Type: text/html"
            echo "Automatic backup of TrueNAS configuration has finished!"
            echo "<br>"
            echo "The configuration file is sent as attachment!"
        ) >> "$logfile"
        # If logfile saving is enabled, copy .tar.gz file to specified location before it (and everything else) is removed below
        if [ "$saveBackup" == "true" ]; then
            cp "${tarfile}" "${backupLocation}/${filename}.tar.gz"
            chown -R avery:admin "${backupLocation}/${filename}.tar.gz"
        fi
        rm "/tmp/${filename}.db"
        rm /tmp/config_backup.md5
        rm /tmp/config_backup.sha256
        rm "${tarfile}"
    fi
else
    # Config backup enabled; set up for html-type content
    (
        echo "--${boundary}"
        echo "Content-Type: text/html"
    ) >> "$logfile"
fi

### Send report
sendmail -q -t -oi < "$logfile"
rm "$logfile"

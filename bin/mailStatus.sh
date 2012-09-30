#! /bin/sh

email=$1
~/bin/showStatus   | /usr/bin/mail -s "Backup Results for `date +"%Y-%m-%d"`"            $email
/sbin/zpool status | /usr/bin/mail -s "zpool status for `date +"%Y-%m-%d"`"              $email
/sbin/zfs list     | /usr/bin/mail -s "zfs list for `date +"%Y-%m-%d"`"                  $email
~/bin/temp.sh      | /usr/bin/mail -s "Temperature of Hard Disks for `date +"%Y-%m-%d"`" $email
sudo ps x | grep backupGT | sed /grep/d >  /tmp/ps
     ps x | grep backupGT | sed /grep/d >> /tmp/ps
cat /tmp/ps        | /usr/bin/mail -s "Backup Processes for `date +"%Y-%m-%d"`"          $email

#!/bin/sh

#source the template
. ${0%/*}/_template


#############################################################
# backups
#############################################################
hostName=vmGuests.example.com   # name used on this backup server

# server to tunnel through
#viaHost=router.example.com
#viaPort=1234
#viaKey=backupGT_1.key

# server to backup
targetHost=esxHost.example.com 
targetPort=22

rsyncOpts="-vi --copy-links --copy-dirlinks"
doBackup -p 1,2,3,7 "$@"


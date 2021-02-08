#!/bin/sh

#source the template
. ${0%/*}/_template


#############################################################
# backups
#############################################################
hostName=${jobFile}   # name used on this backup server

# server to tunnel through
#viaHost=router.example.com
#viaPort=1234
#viaKey=backupGT_1.key

# server to backup
#targetHost=$hostName
targetPort=22

doBackup "$@"


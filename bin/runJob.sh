#! /usr/local/bin/bash

###############################################################################
# This script is used to debug job running issues
# it will run a jobFile named on the command line
###############################################################################


###############################################################################
# include user defined globals and the common library
###############################################################################
. ${0%/*}/../etc/server.conf
. ${0%/*}/common.lib

# redefine $SUDO to include the configured user
if [ -n "$SUDO_USER" ]; then
    SUDO="$SUDO -u $SUDO_USER"
fi


###############################################################################
# globals
###############################################################################
LAST_MODIFIED_DATE='2018.05.05'


###############################################################################
# process options
###############################################################################
printMiniUsage() {
    $ECHO "Usage: $0 <path to jobFile>"
}

printFullUsage() {
    $ECHO "###############################################################################"
    $ECHO "# runQueue (part of the backupGT suite)"
    $ECHO "# Author: Garry Thuna"
    $ECHO "# Created: 2018-05-05"
    $ECHO "# Last modified: ${LAST_MODIFIED_DATE}"
    $ECHO "###############################################################################"
    printMiniUsage
}


if [ "$#" -ne 1 ]; then
    printMiniUsage
    exit 1
fi
jobPath="$1"


###############################################################################
# main
###############################################################################
checkRunningUser


#----------------
# now we have a job lets run it
#----------------
jobDir=`        $SED -n -e '/^jobDir:/!d;         s/^[^[:blank:]]*[[:blank:]]*//p' "${jobPath}"`
jobFile=`       $SED -n -e '/^jobFile:/!d;        s/^[^[:blank:]]*[[:blank:]]*//p' "${jobPath}"`
modName=`       $SED -n -e '/^modName:/!d;        s/^[^[:blank:]]*[[:blank:]]*//p' "${jobPath}"`
utcWindowStart=`$SED -n -e '/^utcWindowStart:/!d; s/^[^[:blank:]]*[[:blank:]]*//p' "${jobPath}"`
utcWindowEnd=`  $SED -n -e '/^utcWindowEnd:/!d;   s/^[^[:blank:]]*[[:blank:]]*//p' "${jobPath}"`
jobParms=`      $SED -n -e '/^jobParms:/!d;       s/^[^[:blank:]]*[[:blank:]]*//p' "${jobPath}"`

logDir="$LOG_ROOT/$jobFile"
logPath="${logDir}/${modName:-$JOB_MODLIST_STATUS}.jobLog"
mkdir -p "$logDir"

{
    if [ -z "$modName" ]; then
        [ -f ${jobDir}/$JOB_CONTROL ]                    && . ${jobDir}/$JOB_CONTROL
        [ -f ${jobDir}/${jobFile}${JOB_CONTROL_SUFFIX} ] && . ${jobDir}/${jobFile}${JOB_CONTROL_SUFFIX}
    
        modListPath=${jobDir}/${jobFile}${JOB_MODLIST_SUFFIX}
        $ECHO "running: " \
            ${jobDir}/${jobFile} -j ${modListPath} $jobParms
        ${jobDir}/${jobFile} -j ${modListPath} $jobParms
        rc=$?
    
        if [ $rc -eq 0 -a -f "${modListPath}" ]; then
            #sucessful so save append jobParms in modList
            parmString=`$ECHO "" | makeAssignment "jobParms" "$jobParms"`
            $SED -i -e "s/$/ ${parmString}/" ${modListPath}
        fi
    
    else
        [ -f ${jobDir}/$JOB_CONTROL ]                               && . ${jobDir}/$JOB_CONTROL
        [ -f ${jobDir}/${jobFile}${JOB_CONTROL_SUFFIX} ]            && . ${jobDir}/${jobFile}${JOB_CONTROL_SUFFIX}
        [ -f ${jobDir}/${jobFile}.${modName}${JOB_CONTROL_SUFFIX} ] && . ${jobDir}/${jobFile}.${modName}${JOB_CONTROL_SUFFIX} 
    
        $ECHO "running:" \
            ${jobDir}/${jobFile} -s "$modName" $jobParms
        ${jobDir}/${jobFile} -s "$modName" $jobParms
        rc=$?
    fi
    $PRINTF '%s\n' "runJob job return code=$rc"
} >> ${logPath} 2>&1


#----------------
# append a status entry to the status file
#----------------
statusDir="${jobDir}/${jobFile}${JOB_STATUS_DIR_SUFFIX}"
statusPath="${statusDir}/${modName:-$JOB_MODLIST_STATUS}" 
statLine=`$SORT $statusPath 2>/dev/null | $TAIL -1`
lastSuccessDate=`$ECHO "$statLine" | parseAssignment lastSuccessDate`
lastFailureDate=`$ECHO "$statLine" | parseAssignment lastFailureDate`
statLine=`$ECHO "" | makeAssignment runDate $timeStamp`
if [ "$rc" -eq 0 ]; then
    $ECHO "runJob success - updating status"
    statLine=`$ECHO "$statLine" | makeAssignment runState SUCCESS`
    statLine=`$ECHO "$statLine" | makeAssignment lastSuccessDate      $timeStamp`
    statLine=`$ECHO "$statLine" | makeAssignment lastFailureDate      $lastFailureDate`
else
    $ECHO "runJob failure - updating status"
    statLine=`$ECHO "$statLine" | makeAssignment runState FAILURE`
    statLine=`$ECHO "$statLine" | makeAssignment lastSuccessDate      $lastSuccessDate`
    statLine=`$ECHO "$statLine" | makeAssignment lastFailureDate      $timeStamp`
fi
$MKDIR -p $statusDir    #ensure that the job status dir exists
$ECHO "$statLine" >> $statusPath



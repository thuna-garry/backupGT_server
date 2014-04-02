#! /usr/local/bin/bash

###############################################################################
# This script searches for module directories on a zfs datastore that are
# simply directories and not zfs datasets, and then converts each to a dataset
###############################################################################


###############################################################################
# include user defined globals and the common library
###############################################################################
. ${0%/*}/../etc/server.conf
. ${0%/*}/common.lib


###############################################################################
# globals
###############################################################################
LAST_MODIFIED_DATE='2014.03.01'


###############################################################################
# process options
###############################################################################
printMiniUsage() {
    $ECHO "Usage: $0 [-d]"
}

printFullUsage() {
    $ECHO "###############################################################################"
    $ECHO "# dir2dataset.sh (part of the backupGT suite)"
    $ECHO "# Author: Garry Thuna"
    $ECHO "# Created: 2014-03-01"
    $ECHO "# Last modified: ${LAST_MODIFIED_DATE}"
    $ECHO "###############################################################################"
    printMiniUsage
    $ECHO "  This script searches for module directories on a zfs datastore that are"
    $ECHO "  simply directories and not zfs datasets, and then converts each to a dataset"
    $ECHO 
    $ECHO "Options:"
    $ECHO "  -d   Dryrun: prints what would be done but doesn't actually do any conversion"
}


parseOptions() {
    local opSsupplied
    while getopts ":d" arg; do
        case $arg in
            d) DRYRUN=1
               ;;
            *) printFullUsage 1>&2
               $ECHO "Option -${OPTARG} not recognized as a valid option." 1>&2
               exit 1
               ;;
        esac
    done
    COMMAND_LINE_PARMS=( "${@:$OPTIND}" )  #save rest of command line as array
}



###############################################################################
# 
###############################################################################
convert_dir2dataset () {
    local dir=$1
    local parentDir=${1%/*}

    #check that the parent is a zfs dataset
    if ! (echo $MOUNT_POINTS | grep -w -q $parentDir); then
        echo "Error: $dir cannot be converted as parent dir is not a zfs dataset"
        return
    fi

    if [ -n "$DRYRUN" ]; then
        echo "dryrun"
        return
    fi

    # a parentDir should not be marked with the custom properties
    zfs inherit -r backupgt:is_backup ${parentDir#/}
    zfs inherit -r backupgt:method    ${parentDir#/}

    zfs create ${dir#/}2
    mv -v ${dir}/* ${dir#/}2
    #tar -C ${dir} -cf - . | tar -C ${dir}2 -xvf -

    # remove the original mount point
    rmdir ${dir}

    # move the temporary into place 
    zfs rename ${dir#/}2 ${dir#/}
    zfs set backupgt:is_backup=yes ${dir#/}
    zfs set backupgt:method=rsync  ${dir#/}
}


###############################################################################
# main
###############################################################################
parseOptions "$@"; set -- "${COMMAND_LINE_PARMS[@]}"

MOUNT_POINTS=`zfs list -o mountpoint`
find $STORAGE_ROOT -type d -maxdepth 2 | sort | while read dir; do
    if ! echo $MOUNT_POINTS | grep -w -q $dir; then
        #dir is a normal directory which should be a zfs dataset
        echo ==========================================================================
        echo = converting $dir
        echo ==========================================================================
        convert_dir2dataset $dir
        echo; echo;
    fi
done



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
    $ECHO "  This script searches for module directories on a zfs datastore that are"
    $ECHO "  simply directories and not zfs datasets, and then converts each to a dataset"
    $ECHO 
    $ECHO "Options:"
    $ECHO "  -d   Dryrun: prints what would be done but doesn't actually do any conversion"
}


parseOptions() {
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
get_dataset () {
    local dir=$1
    zfs list -H -o mountpoint,name | grep $dir[^/] | awk '{print $2}'
}


convert_dir2dataset () {
    local dir=$1
    local parentDir=${1%/*}

    if [ -n "$DRYRUN" ]; then
        echo "dryrun: convert $dir"
        return
    fi

    echo =======================================================================
    echo = converting $dir
    echo =======================================================================

    #check that the parent is a zfs dataset
    local parentDS=`get_dataset $parentDir`
    if [ -z "$parentDS"]; then
        echo "Error: $dir cannot be converted as parent dir is not a zfs dataset"
        echo; echo;
        return
    fi

    # ensure that a parent dataset is not marked with the custom properties
    zfs inherit -r backupgt:is_backup $parentDS
    zfs inherit -r backupgt:method    $parentDS

    local ds=${parentDS}/${dir##*/}
    mv -v ${dir} ${dir}_orig
    zfs create $ds 
    mv -v ${dir}_orig/* ${dir}

    # remove the original dir
    rmdir ${dir}_orig

    # mark the dataset
    zfs set backupgt:is_backup=yes $ds
    zfs set backupgt:method=rsync  $ds

    echo; echo;
}


###############################################################################
# main
###############################################################################
parseOptions "$@"; set -- "${COMMAND_LINE_PARMS[@]}"

find $STORAGE_ROOT -type d -maxdepth 2 | sort | while read dir; do
    if ! zfs list -H -o mountpoint,name | grep -q ${dir}[^/]; then
        #dir is a normal directory which should be a zfs dataset
        convert_dir2dataset $dir
    fi
done


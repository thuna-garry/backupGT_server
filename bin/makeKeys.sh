#!/bin/sh

###############################################################################
# Utility script to generate a batch of ssh keys for use by backupGT when
# a target server has a reduced functionality ssh daemon.
###############################################################################

HOME_DIR=${0%/*}/..
SERVER_DESC=`hostname`
TARGET_SCRIPT="/root/incommingBackups/backupGT.target"


#--------
# command line parameters
#--------
# if both parameters are blank then only the base key will be generated
count=${1:-20}   #the number of keys to make
start=${2:-1}    #counting from (the first key number to make)


#--------
# make sure that the _all.pub file exists
#--------
if [ ! -f "$HOME_DIR/keys/_all.pub" ]; then
    cat > $HOME_DIR/keys/_all.pub <<-__EOF__
	############################################################################
	# `hostname`
	############################################################################
	__EOF__
fi

#--------
# make the keys
#--------
if [ -z "$1" -a -z "$2" ]; then
    list=""
else 
    list=`seq $start $(( start + count -1 ))`
fi
for i in "" $list; do
    if [ -n "$i" ]; then
        keyNumber=`printf "%02s" $i`
        keySuffix=_$keyNumber
    fi

    if [ -f "$HOME_DIR/keys/backupGT${keySuffix}.key" ]; then
        printf 'key number %02s allready exists... skipping.\n' $i
        continue
    else
        printf '\n======== generating key %02s ============\n' $i
    fi

    [ -f $HOME_DIR/keys/backupGT${keySuffix}.key ] && rm -f $HOME_DIR/keys/backupGT${keySuffix}.key
    ssh-keygen -t rsa \
               -b 2048 \
               -q \
               -C "backupGT${keySuffix}@$SERVER_DESC" \
               -f $HOME_DIR/keys/backupGT${keySuffix}.key

    printf 'command="%s%s" ' "$TARGET_SCRIPT" "`echo $keySuffix | sed 's/_/ /'`" >  $HOME_DIR/keys/backupGT${keySuffix}.pub
    cat    $HOME_DIR/keys/backupGT${keySuffix}.key.pub                           >> $HOME_DIR/keys/backupGT${keySuffix}.pub
    rm -f  $HOME_DIR/keys/backupGT${keySuffix}.key.pub

    cat  $HOME_DIR/keys/backupGT${keySuffix}.pub >> $HOME_DIR/keys/_all.pub
    echo                                         >> $HOME_DIR/keys/_all.pub
    echo
done


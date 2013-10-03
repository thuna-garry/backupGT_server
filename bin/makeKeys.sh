#! /bin/sh

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
# make the keys
#--------
if [ -z "$1" -a -z "$2" ]; then
    list=""
else 
    list=`seq -f %02.0f $start $(( start + count -1 ))`
fi
for i in "" $list; do
    if [ -n "$i" ]; then
        keySuffix=_$i
    fi

    if [ -f "$HOME_DIR/keys/backupGT${keySuffix}.key" ]; then
        printf 'key number %s allready exists... skipping.\n' $i
        continue
    else
        printf '\n======== generating key %s ============\n' $i
    fi

    ssh-keygen -t rsa \
               -b 2048 \
               -q \
               -C "backupGT${keySuffix}@$SERVER_DESC" \
               -f $HOME_DIR/keys/backupGT${keySuffix}.key

    printf 'command="%s %3s" ' "$TARGET_SCRIPT" $i      >  $HOME_DIR/keys/backupGT${keySuffix}.pub
    cat    $HOME_DIR/keys/backupGT${keySuffix}.key.pub  >> $HOME_DIR/keys/backupGT${keySuffix}.pub
    rm -f  $HOME_DIR/keys/backupGT${keySuffix}.key.pub

    cat  $HOME_DIR/keys/backupGT${keySuffix}.pub >> $HOME_DIR/keys/_all.pub
    echo                                         >> $HOME_DIR/keys/_all.pub
    echo
done


#--------
# cat all the pub files together
#--------
cat > $HOME_DIR/keys/_all.pub <<-__EOF__
	############################################################################
	# `hostname`
	############################################################################
	__EOF__

cat $HOME_DIR/keys/backupGT*.pub  >> $HOME_DIR/keys/_all.pub

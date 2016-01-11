#! /bin/sh

# script to convert the immediate subdirectories of a zfs dataset to
# be datasets themselves

base=data/backupGT
parent=$1

zfs inherit -r backupgt:is_backup $base/$parent
zfs inherit -r backupgt:method    $base/$parent

for i in /$base/$parent/*; do
    mod=${i##*/}
    echo ==========================================================================
    echo = $base/$parent/${mod}
    echo ==========================================================================
    zfs create $base/$parent/${mod}2
    tar -C /$base/$parent/${mod} -cf - . | tar -C /$base/$parent/${mod}2 -xvf -

    # remove any files from the dataset
    rm -rf /$base/$parent/${mod}

    # destroy the dataset and all its snapshots
    zfs destroy -r $base/$parent/${mod}

    # remove any previously hidden files from under the dataset mount
    rm -rf /$base/$parent/${mod}

    # move the temporary into place 
    zfs rename $base/$parent/${mod}2 $base/$parent/${mod}
    zfs set backupgt:is_backup=yes $base/$parent/${mod}
    zfs set backupgt:method=rsync  $base/$parent/${mod}
    echo; echo; echo; echo;
done



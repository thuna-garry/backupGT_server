#!/bin/bash
for snapshot in `zfs list -H -t snapshot | cut -f 1`
do
    echo destroying $snapshot 
    zfs destroy $snapshot
done


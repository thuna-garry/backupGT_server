#!/bin/sh

zfs list -rt snapshot          \
    | grep -v "[KMG]      -"   \
    | cut -d " " -f 1          \
    | sed -e 's/\(.*\)/echo destroying \1; zfs destroy \1/'  \
    > /tmp/zeroSnaps.sh

#sh /tmp/zeroSnaps.sh


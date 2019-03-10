#!/bin/sh

# bug!!!
# a snapshot has USED = 0B may still have a REFER != 0B

sudo zfs list -rt snapshot     \
    | grep "0B      -"         \
    | cut -d " " -f 1          \
    | sed -e 's/\(.*\)/echo destroying \1; zfs destroy \1/'  \
    > /tmp/zeroSnaps.sh

echo "script /tmp/zeroSnaps.sh has been created"
#sh /tmp/zeroSnaps.sh


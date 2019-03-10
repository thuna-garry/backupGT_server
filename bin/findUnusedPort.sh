#!/bin/bash

###########################################################
# find the first unused port in a range of ports 
#   considers all ip addresses on localhost
#   defaults to range of 30000, 31000
###########################################################

portBeg=${1-30000}
portEnd=${2-31000}

mapfile -t arr < <( \
    sudo lsof -i -P -n -F  \
    | egrep -o ':[0-9]{1,5}->|:[0-9]{1,5}$'  \
    | sed 's/[>:-]//g'  \
    | sort -n  \
    | uniq  \
    )
usedPorts=" ${arr[*]} "   # space separated

for ((p=$portBeg; p<=$portEnd; p++)); do
    if ! grep -q " $p " <<< "$usedPorts"; then
        echo $p
	break;
    fi
done

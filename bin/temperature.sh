#! /bin/sh  

#for i in `ls /dev/da[0-8]`; do
#    echo -n -e $i "\t"
#    sudo smartctl -d atacam -A $i | \
#        grep -i temperature_celsius | \
#        cut -d '-' -f2 |  \
#        cut -d "(" -f1 |  \
#        sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' 
#done

for disk in /dev/da*; do
    echo -n "$disk	"
    echo `smartctl  -A $disk | grep Temperature_Celsius | awk '{print $10}'`
done

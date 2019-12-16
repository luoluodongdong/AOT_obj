#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

BIGHONKER="$workdir/BigHonkingText"
BHT_PID=0



FUNC="bighonker()"
function bighonker()
{
    if [ "${SHOW_BANNERS}" != "FALSE" -a "${SHOW_BANNERS}" != "false" ] ; then
        if [ "$BIGHONKER" != "" ] ; then
            if [ -x "$BIGHONKER" ] ; then
                #echo "@@@@@@@@" "$BIGHONKER" "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${7}" "${8}" "${9}" "${10}" "${11}" "${12}" "${13}" "${14}" "${15}"  "@@@@@@@@"
                "$BIGHONKER" "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${7}" "${8}" "${9}" "${10}" "${11}" "${12}" "${13}" "${14}" "${15}" 2>/dev/null &
                BHT_PID=$!
            fi
        fi
    fi
}

ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

echo $ip

killall `basename "${BIGHONKER}"` 2>/dev/null

if [ "$ip" != "" ] ; then

    OLD_IFS="$IFS" 
    IFS=" " 
    arr=($ip) 
    IFS="$OLD_IFS" 

    i=10

    for s in ${arr[@]} 
    do 
        echo "$s" 
        bighonker -p 600 -h 5% -w 30% -x 70% -y ${i}% -b green " $s "
        i=$(( $i + 6 ))
        echo "$i"

    done
else
    bighonker -p 600 -h 5% -w 30% -x 70% -y 10% -b red " ERR:No IP Address! "
fi

THE_PID=$!


#bighonker -p 60 -h 10% -w 50% -x 50% -y 20% -b green " $ip "

#sleep 2

#killall `basename "${BIGHONKER}"` 2>/dev/null
#kill ${THE_PID} 2>/dev/null

echo "done"

exit


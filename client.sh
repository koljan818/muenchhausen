#!/bin/bash
set -x

PORT=2015
START_CT_NUM=1

requested_ct=$START_CT_NUM
while true; do
    echo $requested_ct | nc -vv -l -p $PORT
    echo "Send $requested_ct containers to server"
    ips=$(echo "Test" | nc -v -l -p $PORT)
    echo "Receive $ips"
    echo "Loading..."
    sleep 40
    nc -v 192.168.3.2 $PORT
    echo "End"
    requested_ct=$((requested_ct+1))
done


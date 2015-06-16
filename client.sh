#!/bin/bash
set -x &&

PORT=2015 &&
START_CT_NUM=1 &&
SERVER_IP_PATTERN="Connection from \[(.*)\] port"

requested_ct=$START_CT_NUM &&

while true; do
    nc_output=$(echo $requested_ct | nc -v -l -p $PORT 2>&1) &&
    if [[ $nc_output =~ $SERVER_IP_PATTERN ]]; then
        server_ip=${BASH_REMATCH[1]}
    else
        echo "Error during parsing nc output - \'$nc_output\'" &&
        exit 1
    fi &&
    echo "Send $requested_ct containers to server" &&
    ips=($(nc -v -l -p $PORT)) &&
    echo "Receive ${ips[@]}" &&
    for ip in ${ips[@]}
    do
        pgbench -h $ip -U postgres -c 100 -T 3600 &
    done &&
    wait &&
    nc -v $server_ip $PORT &&
    requested_ct=$((requested_ct+1))
done

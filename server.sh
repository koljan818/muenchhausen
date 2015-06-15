#!/bin/bash
set -x &&

CLIENT=192.168.3.5 &&
PORT=2015 &&

REPORT_DIR="/root/reports" &&

if [ ! -d $REPORT_DIR ]
then
    mkdir -v -p $REPORT_DIR
fi &&

declare -A KNOWN_COMMANDS=(
#["vmstat"]="while true; do cat /proc/vmstat; sleep 5; done"
#["meminfo"]="while true; do cat /proc/meminfo; sleep 5; done"
["cpu"]="mpstat 5"
["paging"]="sar -B 5"
["disk"]="sar -b 5"
["memory"]="free -b -s 5"
) &&


source prepare_containers.sh &&

requested_ct=$(nc -v $CLIENT $PORT) &&
echo "Accepted $requested_ct containers" &&
prepare_containers $requested_ct &&
echo $ips | nc -v $CLIENT $PORT &&
echo "Test" | nc -v -l -p $PORT &
nc_pid=$! &&
USAGE_DIR="$REPORT_DIR/usage-$requested_ct-$(date +"%Y-%m-%d--%H-%M-%S")" &&
if [ ! -d $USAGE_DIR ]
then
    mkdir -v -p $USAGE_DIR
fi &&
declare -A usage_file_descriptors &&
for id in "${!KNOWN_COMMANDS[@]}"
do
    usage_file="$USAGE_DIR/$id.usage" &&
    exec {usage_file_descriptor}>$usage_file &&
    usage_file_descriptors[$id]=$usage_file_descriptor
    done &&
while kill -0 $nc_pid; do
    for id in "${!KNOWN_COMMANDS[@]}"
    do
        ${KNOWN_COMMANDS[$id]}>&${usage_file_descriptors[$id]}
    done
done
for id in "${!KNOWN_COMMANDS[@]}"
do
    usage_file_descriptor=${usage_file_descriptors[$id]} &&
    exec {usage_file_descriptor}>&-
done


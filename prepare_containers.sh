#!/bin/bash
set -x

START_COMMAND="lxc-start -n"
STOP_COMMAND="lxc-stop -n"
CLONE_COMMAND="lxc-clone -o pg_bench_template -n"
GET_IP_COMMAND="lxc-info -iH -n"

if [ -z "${CLIENT+xxx}" ]; then
    CLIENT="google.com"
fi

lxc_get_status()
{
    started=($(lxc-ls --running \(?\!pg_bench_template\))) &&
    stopped=($(lxc-ls --stopped \(?\!pg_bench_template\))) &&
    all=($(lxc-ls \(?\!pg_bench_template\)))
    
}

print_status()
{
    lxc_get_status &&
    echo "${#started[@]} started containers: ${started[@]}" &&
    echo "${#stopped[@]} stopped containers: ${stopped[@]}" &&
    echo "${#all[@]} total containers: ${all[@]}"
}

generate_id_range()
{
    length=$1 &&
    new_id=$START_CTID &&
    index=0 &&
    ct_range=() &&
    lxc_get_status &&
    while((${#ct_range[@]} != length))
    do
        if ((index < ${#all[@]}))
        then
            if ((new_id != ${all[$index]}))
            then
                ct_range=(${ct_range[@]} $new_id)
            else
                index=$((index+1))
            fi
        else
            ct_range=(${ct_range[@]} $new_id)
        fi &&
        ((new_id++))
    done    
}

prepare_containers()
{
    request=$1 &&
    print_status &&
    to_stop=() &&
    to_start=() &&
    to_create=() &&
    if ((request < ${#started[@]}))
    then
        diff_ct=$((${#started[@]} - request)) &&
        to_stop=(${started[@]: -$diff_ct})
    elif ((request > ${#started[@]} && request <= ${#all[@]}))
    then
        diff_ct=$((request - ${#started[@]})) &&
        to_start=(${stopped[@]:0:$diff_ct})
    elif ((request > ${#all[@]}))
    then
        diff_ct=$((request - ${#all[@]})) &&
        to_start=(${stopped[@]}) &&
        generate_id_range $diff_ct
    fi &&
    echo "To stop ${#to_stop[@]} containers : ${to_stop[@]}" &&
    echo "To start ${#to_start[@]} containers : ${to_start[@]}" &&
    echo "To create ${#ct_range[@]} containers : ${ct_range[@]}" &&
    for ctid in ${to_stop[@]}; do $STOP_COMMAND $ctid & done &&
    for ctid in ${to_start[@]}; do $START_COMMAND $ctid & done &&
    for ctid in ${ct_range[@]}; do ($CLONE_COMMAND $ctid && $START_COMMAND $ctid) & done &&
    wait &&
    print_status &&
    if ((request != ${#started[@]}))
    then
        echo "Error occured during $request container preparation - only ${#started[@]} containers started" >&2
    fi &&
    ips="" &&
    for ctid in ${started[@]}
    do
        while ! lxc-attach -n $ctid -- ping -c 1 $CLIENT; do sleep 2; done
        ipv4=$($GET_IP_COMMAND $ctid | head -n 1) &&
        ips="$ips $ipv4"
    done &&
    echo $ips
}

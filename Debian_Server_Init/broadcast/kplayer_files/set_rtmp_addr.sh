#!/bin/bash
# 获取空格
source "RTMP.txt"
echo "$RTMP_ADDR"
check_var="\"path\": \""
space_prefix=`cat config.json | grep "$check_var"`
space_prefix=`echo "$space_prefix" | sed s/\ /！/g`
space_prefix=($(echo "$space_prefix" | tr "\"" "\n"))
space_prefix=${space_prefix[0]}
idx=`cat config.json | grep -n "$check_var" | gawk '{print $1}' FS=":"`
sed -i "$idx d" config.json
RTMP_ADDR="$space_prefix\"path\": \"$RTMP_ADDR\""
sed -i "$idx i$RTMP_ADDR" config.json
sed -i s/！/\ /g config.json





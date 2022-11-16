#!/bin/bash
# 获取空格
source "RTMP.txt"
source "kconfig.sh"
echo "$RTMP_ADDR"
echo "$KCONF"
check_var="\"path\": \""
space_prefix=`cat "$KCONF" | grep "$check_var"`
space_prefix=`echo "$space_prefix" | sed s/\ /！/g`
space_prefix=($(echo "$space_prefix" | tr "\"" "\n"))
space_prefix=${space_prefix[0]}
idx=`cat "$KCONF" | grep -n "$check_var" | gawk '{print $1}' FS=":"`
sed -i "$idx d" "$KCONF"
RTMP_ADDR="$space_prefix\"path\": \"$RTMP_ADDR\""
sed -i "$idx i$RTMP_ADDR" "$KCONF"
sed -i s/！/\ /g "$KCONF"





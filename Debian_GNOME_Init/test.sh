#!/bin/bash
# 执行apt命令

SET_APT_UPGRADE_WITHOUT_ASKING=0
# 执行apt命令
doApt () {
    if [ "$@" = "update" ];then
        sudo apt-get update
    else if [ "$SET_APT_UPGRADE_WITHOUT_ASKING" -eq 0 ];then
        sudo apt-get $@
    else if [ "$SET_APT_UPGRADE_WITHOUT_ASKING" -eq 1 ];then
        sudo apt-get $@ -y
    fi
}

doApt update

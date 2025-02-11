#!/bin/bash
# 此脚本用于删除服务
REMOVE_SRV_NAME="【$new_srv_name】.service"
sudo rm /lib/systemd/system/"$REMOVE_SRV_NAME"

#!/bin/bash
# 此脚本用于删除本实例的 systemd 服务（不删视频）
REMOVE_SRV_NAME="【$new_srv_name】.service"
sudo systemctl disable --now "$REMOVE_SRV_NAME" 2>/dev/null || true
sudo rm -f /lib/systemd/system/"$REMOVE_SRV_NAME"
sudo systemctl daemon-reload
echo "已删除 $REMOVE_SRV_NAME。推流目录请自行决定是否 rm。"

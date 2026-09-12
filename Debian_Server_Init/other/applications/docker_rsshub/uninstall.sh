#!/bin/bash
## 卸载 docker_rsshub
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=rsshub

# 1. 停止并卸载 systemd 服务
app_remove_service "$SRV_NAME"

# 2. 删除 nginx 配置
app_remove_nginx rsshub.conf

# 3. 停止并删除 docker 容器
sudo docker stop rsshub 2>/dev/null || true
sudo docker rm rsshub 2>/dev/null || true

# 4. 清空断点标记
prompt -s "rsshub 已卸载"

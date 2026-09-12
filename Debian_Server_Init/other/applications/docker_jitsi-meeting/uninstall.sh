#!/bin/bash
## 卸载 docker_jitsi-meeting
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=jitsi-meet-docker

# 1. 停止并卸载 systemd 服务
app_remove_service "$SRV_NAME"

# 2. 停止并删除 docker 容器
if [ -d "$HOME/Applications/docker-jitsi-meet" ]; then
  cd "$HOME/Applications/docker-jitsi-meet"
  sudo docker-compose down 2>/dev/null || true
  cd - >/dev/null
fi

# 3. 删除应用文件
[ -d "$HOME/Applications/docker-jitsi-meet" ] && rm -rf "$HOME/Applications/docker-jitsi-meet"
[ -d "$HOME/.jitsi-meet-cfg" ] && rm -rf "$HOME/.jitsi-meet-cfg"

# 4. 清空断点标记
prompt -s "jitsi-meet-docker 已卸载"

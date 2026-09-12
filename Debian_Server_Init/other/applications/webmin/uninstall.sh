#!/bin/bash
## 卸载 webmin
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

# 1. 停止服务
sudo systemctl stop webmin 2>/dev/null || true
sudo systemctl disable webmin 2>/dev/null || true

# 2. 卸载 webmin 包
if dpkg -l webmin >/dev/null 2>&1; then
  prompt -x "apt-get remove webmin"
  sudo apt-get remove -y webmin
  sudo apt-get autoremove -y
fi

# 3. 删除 nginx 配置
app_remove_nginx webmin.conf

# 4. 清理残留
[ -d /etc/webmin ] && sudo rm -rf /etc/webmin
[ -d /usr/share/webmin ] && sudo rm -rf /usr/share/webmin
[ -f /etc/apt/sources.list.d/webmin.list ] && sudo rm -f /etc/apt/sources.list.d/webmin.list
sudo apt update

# 5. 清空断点标记
prompt -s "webmin 已卸载"

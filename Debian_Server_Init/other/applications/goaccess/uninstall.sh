#!/bin/bash
## 卸载 GoAccess
## 需要 sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=goaccess
GOACCESS_DIR="$HOME/Applications/goaccess"

# 1. 停止并卸载 systemd 服务
app_remove_service "$SRV_NAME"

# 2. 删除 nginx 配置和 htpasswd
app_remove_nginx goaccess.conf
[ -f /etc/nginx/.htpasswd_goaccess ] && sudo rm -f /etc/nginx/.htpasswd_goaccess

# 2.5 删除 GeoIP 城市库（可随时重新下载，不属于用户数据）
sudo rm -rf /usr/local/share/GeoIP

# 3. 删除用户数据（询问，默认保留）
confirm_remove_data "$GOACCESS_DIR" "GoAccess 配置与报告"

# 3.5 删除源码编译的主程序（询问，默认保留；apt 装的不在 /usr/local，不受影响）
if [ -x /usr/local/bin/goaccess ]; then
  echo ""
  prompt -w "⚠ 检测到源码编译的 goaccess 主程序："
  prompt -w "    /usr/local/bin/goaccess（含 man 文档与翻译文件）"
  if comfirm "\e[1;33m? 此操作不可恢复，确认删除吗？(y/N)\e[0m"; then
    sudo rm -f /usr/local/bin/goaccess
    sudo rm -f /usr/local/share/man/man1/goaccess.1
    sudo rm -f /usr/local/share/locale/*/LC_MESSAGES/goaccess.mo
    prompt -s "已删除源码版主程序"
  else
    prompt -i "已保留 /usr/local/bin/goaccess（重装时会跳过编译）"
  fi
fi

# 4. apt 包默认不卸载（按项目约定，避免误伤；仅真安装着才提示）
if dpkg-query -W -f='${Status}' goaccess 2>/dev/null | grep -q "install ok installed"; then
  prompt -w "goaccess apt 包未卸载（如需：sudo apt remove -y goaccess）"
fi

prompt -s "GoAccess 已卸载"

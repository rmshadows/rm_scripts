#!/bin/bash
## 卸载 3x-ui
## 需要 sudo
## 默认保留用户数据（/etc/x-ui/ 含 x-ui.db 数据库），需确认后才删除。
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SRV_NAME=x-ui

# 1. 停止并禁用 systemd 服务
if systemctl is-active --quiet "$SRV_NAME" 2>/dev/null; then
    prompt -x "停止服务 $SRV_NAME"
    sudo systemctl stop "$SRV_NAME"
fi
if systemctl is-enabled --quiet "$SRV_NAME" 2>/dev/null; then
    sudo systemctl disable "$SRV_NAME" 2>/dev/null || true
fi

# 2. 删除 systemd 服务文件
[ -f "/etc/systemd/system/$SRV_NAME.service" ] && sudo rm -f "/etc/systemd/system/$SRV_NAME.service"
[ -f "/lib/systemd/system/$SRV_NAME.service" ] && sudo rm -f "/lib/systemd/system/$SRV_NAME.service"
sudo systemctl daemon-reload
sudo systemctl reset-failed 2>/dev/null || true

# 3. 删除管理命令
[ -f "/usr/bin/x-ui" ] && sudo rm -f "/usr/bin/x-ui"

# 4. 删除程序文件（不含用户数据）
if [ -d "/usr/local/x-ui" ]; then
    prompt -x "删除程序目录 /usr/local/x-ui"
    sudo rm -rf /usr/local/x-ui
fi

# 5. 删除环境变量文件（Debian/Ubuntu）
[ -f "/etc/default/x-ui" ] && sudo rm -f "/etc/default/x-ui"

# 6. 删除 nginx 配置
app_remove_nginx xui.conf

# 7. 用户数据（含 x-ui.db 数据库、inbounds 配置）：默认保留，需确认后删除
confirm_remove_data "/etc/x-ui" "3x-ui 用户数据（数据库 x-ui.db、账号与节点配置）"
DATA_REMOVED=$?

# 8. 完成
prompt -s "3x-ui 已卸载"
if [ "$DATA_REMOVED" -eq 0 ]; then
    prompt -i "用户数据 /etc/x-ui 已删除"
else
    prompt -i "用户数据 /etc/x-ui 已保留"
fi

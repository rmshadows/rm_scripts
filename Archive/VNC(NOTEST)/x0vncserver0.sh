#!/bin/bash

# 使用说明
echo "使用说明: 此脚本用于启动 VNC 服务并显示主屏幕。"
echo "确保已安装 x0vncserver 软件包。"
echo "参数配置："
echo "  DISPLAY_NUM      显示器号，默认为 :0"
echo "  SECURITY_TYPE    安全类型，默认为 None"
echo "    可选项：None, VncAuth, X509, TLSNone"
echo "  USERNAME         用户名，默认为当前用户"
echo "  PASSWORD         VNC 密码，默认为空（不设置）"
echo ""

# 配置变量（可以直接在此修改配置）
DISPLAY_NUM=":0"        # 默认显示器号
SECURITY_TYPE="None"    # 默认安全类型
PASSWORD=""             # 默认不设置密码
# SECURITY_TYPE="TLSVnc,VncAuth"  # 启用 TLS 加密传输 + VncAuth 密码认证
# 可选 SECURITY_TYPE：
#   None        # 不设置安全类型
#   VncAuth    # 基于密码的认证
#   X509       # 使用 X.509 证书认证
#   TLSNone    # 使用 TLS 加密认证
USERNAME=$(whoami)      # 默认使用当前用户

# 检查是否安装了 x0vncserver
if ! command -v x0vncserver &> /dev/null; then
    echo "错误: 未检测到 x0vncserver。请先安装该软件包。"
    exit 1
fi

# 启动 VNC 服务
echo "正在启动 VNC 服务..."
/usr/bin/x0vncserver -PAMService=login -PlainUsers=$USERNAME -SecurityTypes=$SECURITY_TYPE -display $DISPLAY_NUM

# 如果设置了密码，提供密码配置
if [ -n "$PASSWORD" ]; then
    # 设置 VNC 密码（仅当需要时）
    echo "$PASSWORD" | vncpasswd -f
    echo "VNC 密码已设置。"
fi

# 检查是否成功启动
if [ $? -eq 0 ]; then
    echo "VNC 服务已成功启动，显示器：$DISPLAY_NUM，安全类型：$SECURITY_TYPE"
else
    echo "VNC 服务启动失败"
fi


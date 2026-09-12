#!/bin/bash
## 清理 generate_ssl_cert 生成的自签名证书
## 注意：证书可能正被 nginx 站点引用，删除前请确认
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_DIR="$SCRIPT_DIR/nginx_ssl"

if [ -d "$CERT_DIR" ]; then
  prompt -w "⚠ 即将删除自签名证书目录（可能正被 nginx 站点引用）："
  prompt -w "    $CERT_DIR"
  ls -la "$CERT_DIR"
  comfirm "\e[1;33m? 确认删除吗？(y/N)\e[0m"
  if [ $? -eq 1 ]; then
    rm -rf "$CERT_DIR"
    prompt -s "证书文件已删除，可重新运行 generate_nginx_ssl.sh"
  else
    prompt -i "已保留证书目录 $CERT_DIR"
  fi
else
  prompt -i "未找到证书目录 $CERT_DIR"
fi

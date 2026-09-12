#!/bin/bash
# 生成 nginx 用自签名 SSL 证书（不依赖 CA）
# 建议在本目录下执行，或通过 CONF 修改 DOMAIN 后执行

set -e

# 加载全局函数
source "../Lib.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 证书输出目录（在脚本所在目录下）
CERT_DIR="$SCRIPT_DIR/nginx_ssl"
CONFIG_FILE="$SCRIPT_DIR/openssl.cnf"

# 证书所属域名（CN / SAN）：同时用作证书文件名 <DOMAIN>.key / <DOMAIN>.pem。
# 也可通过环境变量覆盖：DOMAIN=your.com ./generate_nginx_ssl.sh
DOMAIN="${DOMAIN:-example.com}"
PRIVATE_KEY="$CERT_DIR/$DOMAIN.key"
CERTIFICATE="$CERT_DIR/$DOMAIN.pem"
CSR="$CERT_DIR/$DOMAIN.csr"

mkdir -p "$CERT_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 未找到 $CONFIG_FILE"
    exit 1
fi

# 检测：证书已存在则跳过
if [ -f "$CERTIFICATE" ] && [ -f "$PRIVATE_KEY" ]; then
  prompt -i "[跳过] SSL 证书已存在（如需重新生成，请先运行 uninstall.sh）"
  echo "证书: $CERTIFICATE"
  echo "私钥: $PRIVATE_KEY"
else
echo "生成私钥和证书签名请求 (CSR)..."
openssl req -new -newkey rsa:2048 -days 3650 -nodes \
  -keyout "$PRIVATE_KEY" -out "$CSR" \
  -config "$CONFIG_FILE" \
  -subj "/C=US/ST=Some-State/O=My Organization/CN=$DOMAIN"

echo "使用自签名证书签署证书..."
openssl x509 -req -in "$CSR" -signkey "$PRIVATE_KEY" -out "$CERTIFICATE" -days 3650 -sha256

echo "SSL 证书和私钥已生成："
echo "证书: $CERTIFICATE"
echo "私钥: $PRIVATE_KEY"
fi

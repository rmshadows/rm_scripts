#!/bin/bash
# 生成 nginx 用自签名 SSL 证书（不依赖 CA）
# 建议在本目录下执行，或通过 CONF 修改 DOMAIN 后执行

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 证书输出目录（在脚本所在目录下）
CERT_DIR="$SCRIPT_DIR/nginx_ssl"
CONFIG_FILE="$SCRIPT_DIR/openssl.cnf"

# 域名，按需修改
DOMAIN="${DOMAIN:-example.com}"
PRIVATE_KEY="$CERT_DIR/$DOMAIN.key"
CERTIFICATE="$CERT_DIR/$DOMAIN.pem"
CSR="$CERT_DIR/$DOMAIN.csr"

mkdir -p "$CERT_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 未找到 $CONFIG_FILE"
    exit 1
fi

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

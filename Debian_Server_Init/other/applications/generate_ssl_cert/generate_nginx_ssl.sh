#!/bin/bash

# 设置证书目录
CERT_DIR="./nginx_ssl"
mkdir -p $CERT_DIR

# 配置文件路径
CONFIG_FILE="./openssl.cnf"

# 证书文件名
DOMAIN="example.com"
PRIVATE_KEY="$CERT_DIR/$DOMAIN.key"
CERTIFICATE="$CERT_DIR/$DOMAIN.pem"
CSR="$CERT_DIR/$DOMAIN.csr"

# 创建私钥和证书签名请求（CSR）
echo "生成私钥和证书签名请求 (CSR)..."
openssl req -new -newkey rsa:2048 -days 3650 -nodes \
  -keyout $PRIVATE_KEY -out $CSR \
  -config $CONFIG_FILE \
  -subj "/C=US/ST=Some-State/O=My Organization/CN=$DOMAIN"

# 使用自签名根证书签署证书（不依赖 CA）
echo "使用自签名证书签署证书..."
openssl x509 -req -in $CSR -signkey $PRIVATE_KEY -out $CERTIFICATE -days 3650 -sha256

# 输出生成的证书和私钥路径
echo "SSL 证书和私钥已生成："
echo "证书: $CERTIFICATE"
echo "私钥: $PRIVATE_KEY"

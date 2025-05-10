#!/bin/bash
# 设置证书的基本信息
COUNTRY="CN"
STATE="Beijing"
LOCALITY="Beijing"
ORG="Example Organization"
ORG_UNIT="Example Unit"
COMMON_NAME="example.com"

# 生成私钥
openssl genrsa -out server.key 2048

# 生成证书请求
openssl req -new -key server.key -out server.csr -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORG}/OU=${ORG_UNIT}/CN=${COMMON_NAME}"

# 生成自签名证书
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

# 将证书和私钥合并成 PEM 文件
cat server.crt server.key > server.pem

echo "PEM 文件生成完成！"


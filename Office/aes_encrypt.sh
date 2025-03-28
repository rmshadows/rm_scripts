#!/bin/bash

# ========== 可修改参数 ==========
PASSWORD="Your_secure_password"  # 你的加密密码
CIPHER="aes-256-cbc"             # 加密算法
EXTENSION=".enc"                 # 加密后缀名
# =================================

# 检测是否传入文件
if [ "$#" -eq 0 ]; then
    echo "用法: 拖拽文件到此脚本 或 ./aes.sh <文件名>"
    exit 1
fi

for FILE in "$@"; do
    if [[ "$FILE" == *"$EXTENSION" ]]; then
        # 解密文件
        DECRYPTED="${FILE%"$EXTENSION"}"
        openssl enc -d -"$CIPHER" -pbkdf2 -in "$FILE" -out "$DECRYPTED" -pass pass:"$PASSWORD" && \
        echo "解密完成: $DECRYPTED" && rm "$FILE"
    else
        # 加密文件
        ENCRYPTED="${FILE}${EXTENSION}"
        openssl enc -"$CIPHER" -salt -pbkdf2 -in "$FILE" -out "$ENCRYPTED" -pass pass:"$PASSWORD" && \
        echo "加密完成: $ENCRYPTED" && rm "$FILE"
    fi
done

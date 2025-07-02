#!/bin/bash

: '
此脚本用于对指定文件进行 AES-256-CBC 加密和解密。
- 如果传入普通文件名，则自动加密，生成同名文件加 .enc 后缀。
- 如果传入以 .enc 结尾的文件，则自动解密，恢复为原文件名。
加密和解密时均需输入密码，密码不会在终端显示。

使用方法：
  ./encdec.sh 文件名

示例：
  ./encdec.sh example.txt      # 加密 example.txt，生成 example.txt.enc
  ./encdec.sh example.txt.enc  # 解密 example.txt.enc，恢复 example.txt
'

set -e

# 加密函数
encrypt_file() {
  local infile="$1"
  local outfile="${infile}.enc"

  echo -n "请输入加密密码："
  read -s password
  echo

  # 使用 openssl 加密
  openssl enc -aes-256-cbc -salt -pbkdf2 -in "$infile" -out "$outfile" -pass pass:"$password"
  echo "✅ 文件已加密为: $outfile"
}

# 解密函数
decrypt_file() {
  local infile="$1"
  local outfile="${infile%.enc}"

  echo -n "请输入解密密码："
  read -s password
  echo

  # 使用 openssl 解密
  openssl enc -d -aes-256-cbc -pbkdf2 -in "$infile" -out "$outfile" -pass pass:"$password"
  echo "✅ 文件已解密为: $outfile"
}

# 主流程
if [ $# -ne 1 ]; then
  echo "用法: $0 文件名"
  exit 1
fi

file="$1"

if [[ "$file" == *.enc ]]; then
  # 文件是 .enc，执行解密
  if [ ! -f "$file" ]; then
    echo "错误：文件不存在 $file"
    exit 1
  fi
  decrypt_file "$file"
else
  # 文件不是 .enc，执行加密
  if [ ! -f "$file" ]; then
    echo "错误：文件不存在 $file"
    exit 1
  fi
  encrypt_file "$file"
fi

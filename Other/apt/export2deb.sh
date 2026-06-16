#!/bin/bash
# 从系统中导出已经安装的软件到deb包（要求是通过apt安装的软件）
# 检查 dpkg-repack 是否已安装
if ! command -v dpkg-repack &> /dev/null; then
  echo "dpkg-repack 未安装，请先安装该工具：sudo apt install dpkg-repack"
  exit 1
fi

# 检查是否提供了包名
if [ -z "$1" ]; then
  echo "请提供要提取的包名"
  exit 1
fi

PACKAGE_NAME=$1

# 查找包是否已安装
dpkg -l | grep -w $PACKAGE_NAME &> /dev/null
if [ $? -ne 0 ]; then
  echo "包 $PACKAGE_NAME 未安装或不存在"
  exit 1
fi

# 使用 dpkg-repack 创建 deb 包
echo "正在将 $PACKAGE_NAME 打包为 .deb 文件..."
dpkg-repack $PACKAGE_NAME

# 显示完成消息
echo "完成：$PACKAGE_NAME 已打包为 .deb 文件"

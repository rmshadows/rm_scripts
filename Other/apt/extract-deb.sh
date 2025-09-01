#!/bin/bash
# 解压deb包

# 检查是否提供了包路径
if [ -z "$1" ]; then
  echo "请提供要解压的 .deb 包路径"
  exit 1
fi

DEB_PACKAGE="$1"

# 检查文件是否存在并且是一个 .deb 文件
if [ ! -f "$DEB_PACKAGE" ]; then
  echo "$DEB_PACKAGE 不是一个有效的文件"
  exit 1
fi

# 创建解压目标目录
EXTRACT_DIR="${DEB_PACKAGE%.deb}"
mkdir -p "$EXTRACT_DIR"

# 解压 deb 包
echo "正在解压 $DEB_PACKAGE 到 $EXTRACT_DIR ..."
dpkg-deb -x "$DEB_PACKAGE" "$EXTRACT_DIR"

# 解压控制文件（包含元数据）
dpkg-deb -e "$DEB_PACKAGE" "$EXTRACT_DIR/DEBIAN"

echo "解压完成！文件已解压到 $EXTRACT_DIR"

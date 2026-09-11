#!/bin/bash
# 打包 Debian_GNOME_Init / Debian_Server_Init 到 release/build/
# 排除 archive/Archive、本地进度与日志等，保留其余完整内容。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

mkdir -p "$BUILD_DIR"
rm -f "$BUILD_DIR"/Debian_GNOME_Init.tar.gz \
      "$BUILD_DIR"/Debian_Server_Init.tar.gz \
      "$BUILD_DIR"/SHA256SUMS

# 共用排除项（匹配任意路径层级中的同名目录/文件）
TAR_EXCLUDES=(
  --exclude='archive'
  --exclude='Archive'
  --exclude='.deploy_progress'
  --exclude='.deploy_credentials'
  --exclude='.deploy_apt_hint'
  --exclude='*.log'
  --exclude='.git'
  --exclude='.gitignore'
)

pack_one() {
  local name="$1"
  local src="$REPO_ROOT/$name"
  local out="$BUILD_DIR/${name}.tar.gz"

  if [ ! -d "$src" ]; then
    echo "缺少目录: $src" >&2
    exit 1
  fi

  echo "打包 $name ..."
  # 归档内顶层为目录名，解压后得到 Debian_*_Init/
  tar -czf "$out" "${TAR_EXCLUDES[@]}" -C "$REPO_ROOT" "$name"
  ls -lh "$out"
}

pack_one "Debian_GNOME_Init"
pack_one "Debian_Server_Init"

(
  cd "$BUILD_DIR"
  sha256sum Debian_GNOME_Init.tar.gz Debian_Server_Init.tar.gz > SHA256SUMS
)

echo
echo "完成，产物在: $BUILD_DIR"
ls -lh "$BUILD_DIR"
echo
echo "校验: sha256sum -c $BUILD_DIR/SHA256SUMS"

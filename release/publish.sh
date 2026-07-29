#!/bin/bash
# 将 release/build 中的包上传到 GitHub Release。
# 用法:
#   ./release/publish.sh              # 交互输入 tag，或创建/更新 release
#   ./release/publish.sh v0.1.0       # 指定 tag
#   ./release/publish.sh v0.1.0 --latest-notes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v gh >/dev/null 2>&1; then
  echo "需要 GitHub CLI: gh" >&2
  exit 1
fi

TAG="${1:-}"
if [ -z "$TAG" ]; then
  read -r -p "Release tag (例如 v0.1.0): " TAG
fi
if [ -z "$TAG" ]; then
  echo "未指定 tag" >&2
  exit 1
fi

if [ ! -f "$BUILD_DIR/Debian_GNOME_Init.tar.gz" ] || [ ! -f "$BUILD_DIR/Debian_Server_Init.tar.gz" ]; then
  echo "产物不存在，先执行: $SCRIPT_DIR/build.sh" >&2
  exit 1
fi

cd "$REPO_ROOT"

ASSETS=(
  "$BUILD_DIR/Debian_GNOME_Init.tar.gz"
  "$BUILD_DIR/Debian_Server_Init.tar.gz"
)
if [ -f "$BUILD_DIR/SHA256SUMS" ]; then
  ASSETS+=("$BUILD_DIR/SHA256SUMS")
fi

NOTES="$(cat <<EOF
Debian GNOME / Server Init 整包（已排除 archive/Archive、本地日志与部署进度文件）。

## 仅下载

\`\`\`bash
curl -fsSL -o Debian_GNOME_Init.tar.gz \\
  https://github.com/rmshadows/rm_scripts/releases/download/${TAG}/Debian_GNOME_Init.tar.gz
tar -xzf Debian_GNOME_Init.tar.gz

curl -fsSL -o Debian_Server_Init.tar.gz \\
  https://github.com/rmshadows/rm_scripts/releases/download/${TAG}/Debian_Server_Init.tar.gz
tar -xzf Debian_Server_Init.tar.gz
\`\`\`

也可用 \`.../releases/latest/download/...\`（需将该 release 标为 latest）。
EOF
)"

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "Release $TAG 已存在，上传/覆盖附件..."
  gh release upload "$TAG" "${ASSETS[@]}" --clobber
else
  echo "创建 Release $TAG ..."
  gh release create "$TAG" "${ASSETS[@]}" \
    --title "$TAG" \
    --notes "$NOTES"
fi

echo
gh release view "$TAG" --json url,tagName,assets -q '{url:.url,tag:.tagName,assets:[.assets[].name]}'

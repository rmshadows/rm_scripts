#!/bin/bash
# 将 release/build 中的包上传到 GitHub Release。
# 用法:
#   ./release/publish.sh                 # 交互输入 tag
#   ./release/publish.sh v0.1.0
#   ./release/publish.sh v0.1.0 --latest
#   ./release/publish.sh v0.1.0 --no-latest
#   ./release/publish.sh v0.1.0 --notes "修复说明"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TAG=""
MARK_LATEST=1
EXTRA_NOTES=""

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --latest)
      MARK_LATEST=1
      shift
      ;;
    --no-latest)
      MARK_LATEST=0
      shift
      ;;
    --notes)
      EXTRA_NOTES="${2:-}"
      shift 2
      ;;
    --latest-notes)
      shift
      ;;
    -*)
      echo "未知参数: $1" >&2
      exit 1
      ;;
    *)
      if [ -n "$TAG" ]; then
        echo "只能指定一个 tag" >&2
        exit 1
      fi
      TAG="$1"
      shift
      ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "需要 GitHub CLI: gh" >&2
  exit 1
fi

if [ -z "$TAG" ]; then
  if [ -t 0 ]; then
    read -r -p "Release tag (例如 v0.1.0): " TAG
  fi
fi
if [ -z "$TAG" ]; then
  echo "未指定 tag" >&2
  exit 1
fi

if [ ! -f "$BUILD_DIR/Debian_GNOME_Init.tar.gz" ] || [ ! -f "$BUILD_DIR/Debian_Server_Init.tar.gz" ]; then
  echo "产物不存在，先执行: $SCRIPT_DIR/build.sh"
  bash "$SCRIPT_DIR/build.sh"
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
Debian GNOME / Server Init 整包（已排除 archive/Archive、本地日志、部署进度与凭据文件）。

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

if [ -n "$EXTRA_NOTES" ]; then
  NOTES="${NOTES}

${EXTRA_NOTES}"
fi

LATEST_ARGS=(--latest=false)
if [ "$MARK_LATEST" = 1 ]; then
  LATEST_ARGS=(--latest)
fi

TARGET="${GITHUB_SHA:-HEAD}"

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "Release $TAG 已存在，上传/覆盖附件..."
  gh release upload "$TAG" "${ASSETS[@]}" --clobber
  gh release edit "$TAG" "${LATEST_ARGS[@]}" --notes "$NOTES"
else
  echo "创建 Release $TAG （target=${TARGET}）..."
  gh release create "$TAG" "${ASSETS[@]}" \
    --title "$TAG" \
    --notes "$NOTES" \
    --target "$TARGET" \
    "${LATEST_ARGS[@]}"
fi

echo
gh release view "$TAG" --json url,tagName,isLatest,assets -q '{url:.url,tag:.tagName,latest:.isLatest,assets:[.assets[].name]}'

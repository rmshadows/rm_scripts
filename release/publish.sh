#!/bin/bash
# 将 release/build 中的包上传到 GitHub Release。
# 用法:
#   ./release/publish.sh                 # 交互输入版本 tag，并更新滚动通道 debian-init
#   ./release/publish.sh v0.1.0
#   ./release/publish.sh v0.1.0 --no-rolling
#   ./release/publish.sh v0.1.0 --notes "修复说明"
#
# 一键 curl 用固定 tag debian-init（不要用 /releases/latest/，那个可能是 PDF 手动 Release）。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROLLING_TAG="debian-init"

TAG=""
MARK_LATEST=0
DO_ROLLING=1
EXTRA_NOTES=""

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
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
    --rolling)
      DO_ROLLING=1
      shift
      ;;
    --no-rolling)
      DO_ROLLING=0
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
    read -r -p "版本 tag（例如 v0.1.0；一键通道固定为 ${ROLLING_TAG}）: " TAG
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

make_notes() {
  local shown_tag="$1"
  cat <<EOF
Debian GNOME / Server Init 整包（已排除 archive/Archive、本地日志、部署进度与凭据文件）。

一键拉取请用固定 tag \`${ROLLING_TAG}\`（与 PDF 等其它 Release 互不影响，不要用 /releases/latest/）：

\`\`\`bash
curl -fsSL -o Debian_GNOME_Init.tar.gz \\
  https://github.com/rmshadows/rm_scripts/releases/download/${ROLLING_TAG}/Debian_GNOME_Init.tar.gz
tar -xzf Debian_GNOME_Init.tar.gz
\`\`\`

本包对应 tag：\`${shown_tag}\`
EOF
  if [ -n "$EXTRA_NOTES" ]; then
    printf '\n%s\n' "$EXTRA_NOTES"
  fi
}

LATEST_ARGS=(--latest=false)
if [ "$MARK_LATEST" = 1 ]; then
  echo "警告: --latest 会把仓库的 GitHub latest 指到 Init，PDF 手动 Release 可能被挤掉。" >&2
  LATEST_ARGS=(--latest)
fi

TARGET="${GITHUB_SHA:-HEAD}"

# recreate=1：删掉旧 Release+tag 再建，让滚动通道指向当前 commit
publish_tag() {
  local tag="$1"
  local title="$2"
  local recreate="${3:-0}"
  local notes
  notes="$(make_notes "$tag")"

  if [ "$recreate" = 1 ] && gh release view "$tag" >/dev/null 2>&1; then
    echo "更新滚动通道 $tag ：删除旧 Release 后重建..."
    gh release delete "$tag" --yes --cleanup-tag
  fi

  if gh release view "$tag" >/dev/null 2>&1; then
    echo "Release $tag 已存在，上传/覆盖附件..."
    gh release upload "$tag" "${ASSETS[@]}" --clobber
    gh release edit "$tag" "${LATEST_ARGS[@]}" --title "$title" --notes "$notes"
  else
    echo "创建 Release $tag （target=${TARGET}）..."
    gh release create "$tag" "${ASSETS[@]}" \
      --title "$title" \
      --notes "$notes" \
      --target "$TARGET" \
      "${LATEST_ARGS[@]}"
  fi
  # 旧版 gh（Actions runner）没有 isLatest 字段
  gh release view "$tag" --json url,tagName,assets -q '{url:.url,tag:.tagName,assets:[.assets[].name]}'
}

# 版本快照（可 pinned）；默认不标 GitHub latest
if [ "$TAG" = "$ROLLING_TAG" ]; then
  publish_tag "$ROLLING_TAG" "Debian Init (rolling)" 1
else
  publish_tag "$TAG" "Debian Init $TAG" 0
  if [ "$DO_ROLLING" = 1 ]; then
    # 滚动通道永远不抢 latest
    MARK_LATEST=0
    LATEST_ARGS=(--latest=false)
    publish_tag "$ROLLING_TAG" "Debian Init (rolling)" 1
  fi
fi

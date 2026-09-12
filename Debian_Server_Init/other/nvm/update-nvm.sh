#!/bin/bash
# 升级 nvm.sh 里钉死的上游版本号（类似 git pull）
# 用法:
#   ./update-nvm.sh             更新到上游最新 tag
#   ./update-nvm.sh v0.40.7     钉到指定版本（0.40.7 也可以）
#   ./update-nvm.sh --check     只检查是否有新版，不改动
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/nvm-sh/nvm"
RAW_BASE="https://raw.githubusercontent.com/nvm-sh/nvm"
NVM_SH="$SCRIPT_DIR/nvm.sh"

say() { echo "==> $*"; }

current_tag() {
    grep -oE 'nvm-sh/nvm/v[0-9]+\.[0-9]+\.[0-9]+' "$NVM_SH" 2>/dev/null \
        | head -n1 | sed 's|.*/||' || true
}

latest_tag_via_git() {
    git ls-remote --tags --refs "$REPO_URL.git" 2>/dev/null \
        | awk -F'/' '{print $NF}' \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1
}

latest_tag_via_api() {
    curl -fsSL "https://api.github.com/repos/nvm-sh/nvm/releases/latest" 2>/dev/null \
        | grep -oE '"tag_name": *"v[0-9]+\.[0-9]+\.[0-9]+"' \
        | head -n1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+'
}

tag_exists() {
    curl -fsI "$RAW_BASE/$1/install.sh" >/dev/null 2>&1
}

TARGET=""
CHECK_ONLY=0
case "${1:-}" in
    "") ;;
    --check|-c) CHECK_ONLY=1 ;;
    v[0-9]*) TARGET="$1" ;;
    [0-9]*) TARGET="v$1" ;;
    *) echo "用法: $0 [--check|vX.Y.Z]" >&2; exit 2 ;;
esac

[ -f "$NVM_SH" ] || { echo "找不到 $NVM_SH" >&2; exit 1; }

OLD_TAG="$(current_tag)"
if [ -z "$OLD_TAG" ]; then
    echo "无法从 nvm.sh 识别当前钉住的版本号" >&2
    exit 1
fi

if [ -z "$TARGET" ]; then
    say "查询上游最新版本 ..."
    TARGET="$(latest_tag_via_git || true)"
    if [ -z "$TARGET" ]; then
        say "git ls-remote 没拿到结果，改用 GitHub API ..."
        TARGET="$(latest_tag_via_api || true)"
    fi
fi
[ -n "$TARGET" ] || { echo "无法获取上游版本，请检查网络" >&2; exit 1; }

say "当前钉住: $OLD_TAG"
say "目标版本: $TARGET"

if [ "$OLD_TAG" = "$TARGET" ]; then
    say "已是最新，无需更新"
    exit 0
fi

if ! tag_exists "$TARGET"; then
    echo "上游不存在 $TARGET（install.sh 请求失败）" >&2
    exit 1
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
    say "有新版本: $OLD_TAG -> $TARGET（--check 不改动；去掉参数执行更新）"
    exit 0
fi

sed -i "s|$OLD_TAG|$TARGET|g" "$NVM_SH"
say "nvm.sh 已更新（$(grep -c "$TARGET" "$NVM_SH") 处版本号已替换）"
say "完成。可用 git diff 查看改动，git checkout 可回滚。"

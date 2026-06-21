#!/bin/bash
# 将本机白霜拼音配置同步到 5/RIME_FROST，供离线部署使用
# 自动排除用户词库、自定义短语、机器标识等隐私/个人数据

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$SCRIPT_DIR/../RIME_FROST"
TEMPLATE_DIR="$SCRIPT_DIR/rime_frost_templates"
SRC="${1:-$HOME/.local/share/fcitx5/rime}"

# 不同步到离线包的个人/机器相关文件（RIME 首次部署时会自动重建部分文件）
RSYNC_PRIVATE_EXCLUDES=(
	'build/'
	'sync/'
	'*.userdb/'
	'*.userdb'
	'user.yaml'
	'installation.yaml'
	'custom_phrase.txt'
	'custom_phrase_double.txt'
	'default.custom.yaml'
	'rime_frost.custom.yaml'
	'*.custom.yaml'
	'*udict*'
)

if [ ! -f "$SRC/rime_frost.schema.yaml" ]; then
	echo "错误：源目录不是白霜拼音配置（缺少 rime_frost.schema.yaml）" >&2
	echo "用法: $0 [源目录]" >&2
	echo "示例: $0 ~/.local/share/fcitx5/rime" >&2
	exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
	echo "错误：需要 rsync" >&2
	exit 1
fi

mkdir -p "$DEST"
_excludes=(--exclude '.gitkeep' --exclude 'README.md')
for _pat in "${RSYNC_PRIVATE_EXCLUDES[@]}"; do
	_excludes+=(--exclude "$_pat")
done

echo "同步白霜方案文件（已排除个人词库/短语/机器标识）…"
rsync -a --delete "${_excludes[@]}" "$SRC/" "$DEST/"

# 空自定义短语模板（schema 需要此文件，但不包含个人词条）
if [ -f "$TEMPLATE_DIR/custom_phrase.txt" ]; then
	cp "$TEMPLATE_DIR/custom_phrase.txt" "$DEST/custom_phrase.txt"
fi

# 再次清理可能遗留的隐私文件
for _f in user.yaml installation.yaml custom_phrase_double.txt; do
	rm -f "$DEST/$_f"
done
find "$DEST" \( -name '*.userdb' -o -name '*udict*' \) -print -delete 2>/dev/null || true

echo "已同步白霜离线包 → $DEST（不含个人词库）"
du -sh "$DEST"

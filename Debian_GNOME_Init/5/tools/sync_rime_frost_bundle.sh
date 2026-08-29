#!/bin/bash
# 将本机白霜拼音配置精简同步到 5/RIME_FROST（可提交 git，部署时不访问 GitHub）
# 排除：隐私数据、作者原料目录、未启用的腾讯大词库、小狼毫残留

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$SCRIPT_DIR/../RIME_FROST"
TEMPLATE_DIR="$SCRIPT_DIR/rime_frost_templates"
SRC="${1:-$HOME/.local/share/fcitx5/rime}"

RSYNC_EXCLUDES=(
	# 运行时生成 / 隐私
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
	# 非运行时：词库原料、文档图、作者脚本
	'others/'
	# 方案里已注释，不加载
	'cn_dicts/tencent.dict.yaml'
	# Windows 小狼毫 / 非白霜方案残留
	'weasel.yaml'
	'luna_pinyin.dict.yaml'
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
for _pat in "${RSYNC_EXCLUDES[@]}"; do
	_excludes+=(--exclude "$_pat")
done

echo "同步精简白霜方案（排除 others/、tencent、隐私文件）…"
rsync -a --delete "${_excludes[@]}" "$SRC/" "$DEST/"

if [ -f "$TEMPLATE_DIR/custom_phrase.txt" ]; then
	cp "$TEMPLATE_DIR/custom_phrase.txt" "$DEST/custom_phrase.txt"
fi

for _f in user.yaml installation.yaml custom_phrase_double.txt weasel.yaml luna_pinyin.dict.yaml; do
	rm -f "$DEST/$_f"
done
rm -rf "$DEST/others" "$DEST/cn_dicts/tencent.dict.yaml"
find "$DEST" \( -name '*.userdb' -o -name '*udict*' \) -print -delete 2>/dev/null || true

echo "已同步精简白霜离线包 → $DEST"
du -sh "$DEST"
test -f "$DEST/rime_frost.schema.yaml" && echo "OK: rime_frost.schema.yaml"
test ! -d "$DEST/others" && echo "OK: 无 others/"
test ! -f "$DEST/cn_dicts/tencent.dict.yaml" && echo "OK: 无 tencent 词库"

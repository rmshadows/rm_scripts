#!/bin/bash
# 从 shared/zshrc.base.src 生成 zshrc。占位符【$CURRENT_USER】保留，安装时或手工再替换。
# 主干里 # @@ZSHRC_GNOME@@ 换成 shared/zshrc.gnome.snippet，# @@ZSHRC_SERVER@@ 换成 shared/zshrc.server.snippet。
# 片段文件为空表示这一侧不加内容（zshrc.server.snippet 目前是空文件，提交时请保留）。代理端口两边都是 10808。
# 谁来调用：release/build.sh 打包前一定会跑。
#   Debian_GNOME_Init/2/setup.sh 与 Debian_Server_Init/2/setup.sh
#   只在克隆的完整仓库里跑（能找到 shared/sync-zshrc.sh）。
#   发布包里没有 shared/，安装时跳过，用打包前已经写好的 zshrc.src。
# 写出这 4 处：
#   Debian_GNOME_Init/2/zshrc.src          主干 + GNOME 片段
#   Debian_Server_Init/2/zshrc.src         主干 + Server 片段
#   sample/261003-zshrc                    与 GNOME 相同，文件头多两行说明
#   systweak/setup-zsh.sh                  只替换 ZSHRC_TEMPLATE_EOF 内嵌正文，与 GNOME 相同
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE="$ROOT/shared/zshrc.base.src"
GNOME_SNIPPET="$ROOT/shared/zshrc.gnome.snippet"
SERVER_SNIPPET="$ROOT/shared/zshrc.server.snippet"
GNOME_MARKER='# @@ZSHRC_GNOME@@'
SERVER_MARKER='# @@ZSHRC_SERVER@@'
GNOME_OUT="$ROOT/Debian_GNOME_Init/2/zshrc.src"
SERVER_OUT="$ROOT/Debian_Server_Init/2/zshrc.src"
SAMPLE_OUT="$ROOT/sample/261003-zshrc"
SETUP_ZSH="$ROOT/systweak/setup-zsh.sh"

[[ -f "$BASE" && -f "$GNOME_SNIPPET" && -f "$SERVER_SNIPPET" && -f "$SETUP_ZSH" ]] || {
	echo "缺少主干、片段或 systweak/setup-zsh.sh" >&2
	exit 1
}

emit_side() {
	local own="$1" other="$2" snip="$3" out="$4"
	awk -v own="$own" -v other="$other" -v snip="$snip" '
		BEGIN {
			while ((getline line < snip) > 0) {
				body = body line ORS
				has = 1
			}
			close(snip)
		}
		$0 == own {
			nown++
			if (has) printf "%s", body
			next
		}
		$0 == other {
			nother++
			next
		}
		{ print }
		END {
			if (nown != 1) {
				print "主干里标记必须恰好出现一次: " own > "/dev/stderr"
				exit 1
			}
			if (nother != 1) {
				print "主干里标记必须恰好出现一次: " other > "/dev/stderr"
				exit 1
			}
		}
	' "$BASE" >"$out"
}

emit_side "$GNOME_MARKER" "$SERVER_MARKER" "$GNOME_SNIPPET" "$GNOME_OUT"
emit_side "$SERVER_MARKER" "$GNOME_MARKER" "$SERVER_SNIPPET" "$SERVER_OUT"

{
	echo "# 由 shared/sync-zshrc.sh 生成，内容与 Debian_GNOME_Init/2/zshrc.src 相同。"
	echo "# 占位符【\$CURRENT_USER】请按实际用户名手工替换后再当作 ~/.zshrc 使用。"
	cat "$GNOME_OUT"
} >"$SAMPLE_OUT"

awk -v gnome="$GNOME_OUT" '
	$0 == "  cat <<'\''ZSHRC_TEMPLATE_EOF'\''" {
		print
		while ((getline line < gnome) > 0) print line
		close(gnome)
		skip = 1
		next
	}
	skip && $0 == "ZSHRC_TEMPLATE_EOF" {
		print
		skip = 0
		found = 1
		next
	}
	skip { next }
	{ print }
	END {
		if (!found) {
			print "setup-zsh.sh 里找不到 zshrc 内嵌块" > "/dev/stderr"
			exit 1
		}
	}
' "$SETUP_ZSH" >"$SETUP_ZSH.tmp"
mv "$SETUP_ZSH.tmp" "$SETUP_ZSH"

echo "已生成:"
echo "  $GNOME_OUT"
echo "  $SERVER_OUT"
echo "  $SAMPLE_OUT"
echo "  $SETUP_ZSH"

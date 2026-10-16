#!/bin/bash
# 交互查看 / 迁移 acme.sh。没有 /etc/acme-deploy.conf 也能先查托管目录、再生成配置。
# 安装后：acme-ctl
# 只看状态：acme-ctl status / certs / cron
# 迁移是分开的步骤，没有一键：locate / clear / write-conf / deploy / remove-old
CONF="${ACME_CONF:-/etc/acme-deploy.conf}"

ACME_USER="${ACME_USER:-}"
ACME_BIN="${ACME_BIN:-}"
ACME_HOME="${ACME_HOME:-}"
PRIMARY="${PRIMARY:-}"
DOMAINS="${DOMAINS:-}"
WEBROOT="${WEBROOT:-}"
HTTP="${HTTP:-}"
DEPLOY_DIR="${DEPLOY_DIR:-}"
_home=""

load_conf() {
	ACME_USER=""
	ACME_BIN=""
	ACME_HOME=""
	PRIMARY=""
	DOMAINS=""
	WEBROOT=""
	HTTP=""
	DEPLOY_DIR=""
	_home=""
	if [ ! -f "$CONF" ]; then
		return 1
	fi
	# shellcheck disable=SC1090
	. "$CONF"
	ACME_USER="${ACME_USER:-}"
	ACME_BIN="${ACME_BIN:-}"
	ACME_HOME="${ACME_HOME:-}"
	PRIMARY="${PRIMARY:-}"
	DOMAINS="${DOMAINS:-$PRIMARY}"
	WEBROOT="${WEBROOT:-}"
	HTTP="${HTTP:-nginx}"
	# 误把 acme.sh 文件路径填进 ACME_BIN 时，当成它所在的目录
	if [ -n "$ACME_BIN" ] && [ -f "$ACME_BIN" ] && [ "$(basename "$ACME_BIN")" = "acme.sh" ]; then
		ACME_BIN="$(dirname "$ACME_BIN")"
	fi
	if [ -n "$ACME_USER" ]; then
		_home=$(getent passwd "$ACME_USER" 2>/dev/null | cut -d: -f6 || true)
	fi
	if [ -z "${DEPLOY_DIR:-}" ] && [ -n "$_home" ]; then
		DEPLOY_DIR="${_home}/cert"
	fi
	return 0
}

load_conf || true

# 终端彩色（管道/重定向或 NO_COLOR=1 时自动关掉）
_C0= _Cb= _Cd= _Cr= _Cg= _Cy= _Cc= _Cm=
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
	_C0=$'\033[0m'
	_Cb=$'\033[1m'
	_Cd=$'\033[2m'
	_Cr=$'\033[31m'
	_Cg=$'\033[32m'
	_Cy=$'\033[33m'
	_Cc=$'\033[36m'
	_Cm=$'\033[35m'
fi

say_hdr() {
	printf '\n%s%s════════ %s ════════%s\n' "$_Cc" "$_Cb" "$1" "$_C0"
}

say_end() {
	printf '%s%s════════════════════════════%s\n' "$_Cc" "$_Cd" "$_C0"
}

# say_kv 标签 值 [ok|warn|bad|info|dim]
say_kv() {
	local k="$1" v="$2" tone="${3:-}" color="$_C0"
	case "$tone" in
	ok) color="$_Cg" ;;
	warn) color="$_Cy" ;;
	bad) color="$_Cr" ;;
	info) color="$_Cc" ;;
	dim) color="$_Cd" ;;
	esac
	printf '  %s%-12s%s %s%s%s\n' "$_Cd" "$k" "$_C0" "$color" "$v" "$_C0"
}

say_ok() { printf '  %s%s%s\n' "$_Cg" "$*" "$_C0"; }
say_warn() { printf '  %s%s%s\n' "$_Cy" "$*" "$_C0"; }
say_bad() { printf '  %s%s%s\n' "$_Cr" "$*" "$_C0"; }
say_info() { printf '  %s%s%s\n' "$_Cc" "$*" "$_C0"; }
say_dim() { printf '  %s%s%s\n' "$_Cd" "$*" "$_C0"; }

need_tty() {
	if [ -t 0 ]; then
		return 0
	fi
	printf '%s这一步要在终端里确认。%s\n' "$_Cr" "$_C0" >&2
	return 1
}

need_root() {
	if [ "$(id -u)" -eq 0 ]; then
		return 0
	fi
	printf '%s请用 root 运行这一步。%s\n' "$_Cr" "$_C0" >&2
	return 1
}

confirm_no() {
	local reply
	read -r -p "$1 [y/N]: " reply || return 1
	case "$reply" in
	y | Y | yes | YES) return 0 ;;
	*) return 1 ;;
	esac
}

ask_default() {
	local prompt="$1" default="$2" reply
	if [ -n "$default" ]; then
		read -r -p "$prompt [$default]: " reply || return 1
		printf '%s\n' "${reply:-$default}"
	else
		read -r -p "$prompt: " reply || return 1
		printf '%s\n' "$reply"
	fi
}

as_user() {
	if [ -z "$ACME_USER" ] || [ "$(id -un)" = "$ACME_USER" ]; then
		"$@"
		return
	fi
	if [ "$(id -u)" -eq 0 ]; then
		runuser -u "$ACME_USER" -- env -u SUDO_USER -u SUDO_UID -u SUDO_GID -u SUDO_COMMAND \
			HOME="${_home:-}" USER="$ACME_USER" LOGNAME="$ACME_USER" "$@"
		return
	fi
	echo "请用 $ACME_USER 或 root 运行。" >&2
	return 1
}

acme_bin() {
	if [ -n "$ACME_BIN" ] && [ -x "$ACME_BIN/acme.sh" ]; then
		printf '%s\n' "$ACME_BIN/acme.sh"
		return 0
	fi
	if [ -n "$ACME_HOME" ] && [ -x "$ACME_HOME/acme.sh" ]; then
		printf '%s\n' "$ACME_HOME/acme.sh"
		return 0
	fi
	return 1
}

cert_conf() {
	local d="$1" f
	for f in \
		"$ACME_HOME/${d}_ecc/${d}.conf" \
		"$ACME_HOME/${d}/${d}.conf"; do
		if [ -f "$f" ]; then
			printf '%s\n' "$f"
			return 0
		fi
	done
	return 1
}

conf_field() {
	local file="$1" key="$2" val
	[ -f "$file" ] || return 1
	val=$(sed -n "s/^${key}=//p" "$file" | head -n 1 | tr -d "'\"")
	[ -n "$val" ] || return 1
	printf '%s\n' "$val"
}

# 路径落在托管目录或新的部署目录里时，清除/删旧都不许碰
path_under() {
	local target="$1" base="$2" real
	[ -n "$target" ] && [ -n "$base" ] || return 1
	real=$(readlink -f "$target" 2>/dev/null || printf '%s\n' "$target")
	base=$(readlink -f "$base" 2>/dev/null || printf '%s\n' "$base")
	case "$real" in
	"$base" | "$base"/*) return 0 ;;
	*) return 1 ;;
	esac
}

path_protected() {
	local target="$1" base real
	[ -n "$target" ] || return 1
	real=$(readlink -f "$target" 2>/dev/null || printf '%s\n' "$target")
	for base in "$ACME_HOME" "$DEPLOY_DIR"; do
		[ -n "$base" ] || continue
		base=$(readlink -f "$base" 2>/dev/null || printf '%s\n' "$base")
		case "$real" in
		"$base" | "$base"/*) return 0 ;;
		esac
	done
	return 1
}

discover_homes() {
	local seen="" u home line p
	add_home() {
		local d="$1"
		[ -n "$d" ] || return 0
		d="${d%/}"
		[ -d "$d" ] || return 0
		case " $seen " in
		*" $d "*) return 0 ;;
		esac
		if [ -x "$d/acme.sh" ] || compgen -G "$d/*/fullchain.cer" >/dev/null || compgen -G "$d/*_ecc/fullchain.cer" >/dev/null; then
			seen="$seen $d"
			printf '%s\n' "$d"
		fi
	}
	add_home "$ACME_BIN"
	add_home "$ACME_HOME"
	if [ -f /usr/local/bin/acme.sh ]; then
		line=$(sed -n 's/.*exec[[:space:]]\{1,\}\([^[:space:]]*\)\/acme\.sh.*/\1/p' /usr/local/bin/acme.sh | head -n 1)
		add_home "$line"
	fi
	while IFS=: read -r u _ _ _ _ home _; do
		[ -n "$home" ] && [ "$home" != "/" ] || continue
		add_home "$home/.acme.sh"
	done < <(getent passwd 2>/dev/null || true)
	for u in ${ACME_USER:-} root "$(id -un)"; do
		[ -n "$u" ] || continue
		line=$(crontab -u "$u" -l 2>/dev/null | sed -n 's/.*--home[[:space:]]\{1,\}\([^[:space:]]*\).*/\1/p' | head -n 1 || true)
		add_home "$line"
	done
}

domains_in() {
	local home="$1" dir base
	[ -d "$home" ] || return 0
	for dir in "$home"/*/; do
		[ -d "$dir" ] || continue
		base=$(basename "$dir")
		case "$base" in
		ca | deploy | dnsapi | notify) continue ;;
		esac
		[ -f "${dir}fullchain.cer" ] || continue
		printf '%s\n' "${base%_ecc}"
	done | awk '!seen[$0]++'
}

cert_dir_for() {
	local home="$1" domain="$2"
	if [ -f "$home/${domain}_ecc/fullchain.cer" ]; then
		printf '%s\n' "$home/${domain}_ecc"
		return 0
	fi
	if [ -f "$home/${domain}/fullchain.cer" ]; then
		printf '%s\n' "$home/${domain}"
		return 0
	fi
	return 1
}

domain_confs() {
	local home="$1" domain="$2" f
	for f in "$home/${domain}_ecc/${domain}.conf" "$home/${domain}/${domain}.conf"; do
		[ -f "$f" ] && printf '%s\n' "$f"
	done
}

registered_install_paths() {
	local home="$1" domain="$2" f key val
	for f in $(domain_confs "$home" "$domain"); do
		for key in Le_RealFullChainPath Le_RealKeyPath Le_RealCertPath Le_RealCACertPath; do
			val=$(conf_field "$f" "$key" || true)
			[ -n "$val" ] && printf '%s\n' "$val"
		done
	done | awk '!seen[$0]++'
}

old_cert_candidates() {
	local domain="$1" home="$2" p
	[ -n "$domain" ] || return 0
	for p in \
		"/etc/ssl/${domain}.pem" \
		"/etc/ssl/${domain}.key" \
		"/etc/ssl/${domain}.crt"; do
		[ -f "$p" ] && printf '%s\n' "$p"
	done
	if [ -n "$home" ]; then
		registered_install_paths "$home" "$domain"
	fi
}

# 读证书到期：输出 "ISO日期|剩余天数|tone"，tone=ok/warn/bad
cert_expiry_line() {
	local cer="$1" end end_epoch now days tone
	[ -f "$cer" ] || return 1
	command -v openssl >/dev/null 2>&1 || return 1
	end=$(openssl x509 -in "$cer" -noout -enddate 2>/dev/null | sed 's/^notAfter=//') || return 1
	[ -n "$end" ] || return 1
	end_epoch=$(date -d "$end" +%s 2>/dev/null || true)
	now=$(date +%s)
	if [ -n "$end_epoch" ]; then
		days=$(((end_epoch - now) / 86400))
		if [ "$days" -lt 0 ]; then
			tone=bad
		elif [ "$days" -le 30 ]; then
			tone=warn
		else
			tone=ok
		fi
		printf '%s|%s|%s\n' "$(date -d "$end" '+%Y-%m-%d %H:%M' 2>/dev/null || printf '%s' "$end")" "$days" "$tone"
	else
		printf '%s||info\n' "$end"
	fi
}

print_one_cert() {
	local home="$1" domain="$2" cdir cer info end days tone conf next reload san kind
	cdir=$(cert_dir_for "$home" "$domain" || true)
	[ -n "$cdir" ] || return 1
	cer="$cdir/fullchain.cer"
	case "$cdir" in
	*_ecc) kind=ecc ;;
	*) kind=rsa ;;
	esac
	printf '  %s●%s %s%s%s  %s(%s)%s\n' "$_Cg" "$_C0" "$_Cb" "$domain" "$_C0" "$_Cd" "$kind" "$_C0"
	say_kv "库存" "$cer" dim
	if info=$(cert_expiry_line "$cer"); then
		IFS='|' read -r end days tone <<<"$info"
		if [ -n "$days" ]; then
			if [ "$days" -lt 0 ]; then
				say_kv "到期" "$end（已过期 $((-days)) 天）" bad
			else
				say_kv "到期" "$end（还剩 ${days} 天）" "$tone"
			fi
		else
			say_kv "到期" "$end" info
		fi
		san=$(names_from_cert "$cer" 2>/dev/null || true)
		[ -n "$san" ] && say_kv "SAN" "$san" dim
	else
		say_kv "到期" "读不到（缺 openssl 或证书坏了）" warn
	fi
	conf=""
	for conf in "$home/${domain}_ecc/${domain}.conf" "$home/${domain}/${domain}.conf"; do
		[ -f "$conf" ] || continue
		next=$(conf_field "$conf" Le_NextRenewTimeStr 2>/dev/null || conf_field "$conf" Le_NextRenewTime 2>/dev/null || true)
		reload=$(conf_field "$conf" Le_ReloadCmd 2>/dev/null || true)
		[ -n "$next" ] && say_kv "下次续签" "$next" info
		[ -n "$reload" ] && say_kv "续签钩子" "$reload" dim
		break
	done
}

# 列出托管目录里的证书（可指定 home；默认配置里的 ACME_HOME，没有就扫描）
show_certs() {
	local homes home domains domain count=0
	say_hdr "托管证书"
	if [ -n "${1:-}" ]; then
		homes="$1"
	elif [ -n "$ACME_HOME" ] && [ -d "$ACME_HOME" ]; then
		homes="$ACME_HOME"
	else
		homes=$(discover_homes || true)
	fi
	if [ -z "$homes" ]; then
		say_bad "没找到托管目录。先 acme-ctl locate，或写好 $CONF。"
		say_end
		return 1
	fi
	while IFS= read -r home; do
		[ -n "$home" ] || continue
		say_kv "目录" "$home" info
		domains=$(domains_in "$home" || true)
		if [ -z "$domains" ]; then
			say_warn "还没有证书"
			echo
			continue
		fi
		while IFS= read -r domain; do
			[ -n "$domain" ] || continue
			print_one_cert "$home" "$domain" || true
			count=$((count + 1))
			echo
		done <<<"$domains"
	done <<<"$homes"
	if [ "$count" -eq 0 ]; then
		say_warn "合计 0 张证书"
	else
		say_ok "合计 ${count} 张证书"
	fi
	say_end
}

cron_spool_path() {
	local u="$1"
	if [ -f "/var/spool/cron/crontabs/$u" ]; then
		printf '%s\n' "/var/spool/cron/crontabs/$u"
		return 0
	fi
	if [ -f "/var/spool/cron/$u" ]; then
		printf '%s\n' "/var/spool/cron/$u"
		return 0
	fi
	return 1
}

# 输出: 来源文件<TAB>crontab行
collect_acme_cron() {
	local u line file f
	for u in ${ACME_USER:-} root "$(id -un)"; do
		[ -n "$u" ] || continue
		while IFS= read -r line; do
			[ -n "$line" ] || continue
			case "$line" in
			\#*) continue ;;
			esac
			if file=$(cron_spool_path "$u"); then
				printf '%s\t%s\n' "$file" "$line"
			else
				printf 'crontab -u %s\t%s\n' "$u" "$line"
			fi
		done < <(crontab -u "$u" -l 2>/dev/null | grep -E 'acme\.sh|[[:space:]]acme[[:space:]]' || true)
	done
	# /etc/cron.d 里也可能有
	for f in /etc/cron.d/*; do
		[ -f "$f" ] || continue
		while IFS= read -r line; do
			[ -n "$line" ] || continue
			case "$line" in
			\#*) continue ;;
			esac
			printf '%s\t%s\n' "$f" "$line"
		done < <(grep -E 'acme\.sh' "$f" 2>/dev/null || true)
	done
}

show_cron() {
	local found=0 file line tone
	say_hdr "自动续签（cron）"
	if [ -n "$ACME_USER" ]; then
		say_kv "业务用户" "$ACME_USER" info
	else
		say_kv "业务用户" "未配置（$CONF）" warn
	fi
	while IFS=$'\t' read -r file line; do
		[ -n "$line" ] || continue
		found=1
		if printf '%s' "$line" | grep -qF -- '--cron'; then
			tone=ok
			say_kv "状态" "已找到 acme.sh --cron" ok
		else
			tone=warn
			say_kv "状态" "有 acme 相关行，但不是 --cron" warn
		fi
		say_kv "来源文件" "$file" info
		printf '  %s%-12s%s %s%s%s\n' "$_Cd" "crontab行" "$_C0" "$_Cb" "$line" "$_C0"
		echo
	done < <(collect_acme_cron | awk -F '\t' '!seen[$0]++')
	if [ "$found" -eq 0 ]; then
		say_bad "没有找到自动续签。"
		say_dim "安装 acme.sh 时通常会给业务用户写一条："
		say_dim '  <分> <时> * * * "/path/.acme.sh"/acme.sh --cron --home "/path/.acme.sh"'
		if [ -n "$ACME_USER" ]; then
			say_dim "查看: crontab -u $ACME_USER -l"
			if file=$(cron_spool_path "$ACME_USER"); then
				say_dim "Debian 上文件一般是: $file"
			else
				say_dim "Debian 上文件一般是: /var/spool/cron/crontabs/$ACME_USER"
			fi
		fi
	fi
	# systemd timer 顺带扫一眼
	if command -v systemctl >/dev/null 2>&1; then
		line=$(systemctl list-timers --all 2>/dev/null | grep -i acme || true)
		if [ -n "$line" ]; then
			say_kv "systemd" "还发现 timer（少见）" info
			say_dim "$line"
		fi
	fi
	say_end
	[ "$found" -gt 0 ]
}

show_locate() {
	local homes home owner domains domain cdir f p
	say_hdr "acme 托管位置"
	homes=$(discover_homes || true)
	if [ -z "$homes" ]; then
		say_bad "没找到 acme.sh 目录。常见位置是 /home/用户/.acme.sh"
		say_end
		return 1
	fi
	while IFS= read -r home; do
		[ -n "$home" ] || continue
		owner=$(stat -c '%U' "$home" 2>/dev/null || echo 未知)
		say_kv "托管目录" "$home" info
		say_kv "属主" "$owner"
		if [ -x "$home/acme.sh" ]; then
			say_kv "程序" "$home/acme.sh" ok
		else
			say_kv "程序" "这个目录里没有 acme.sh（可能只是证书库）" warn
		fi
		domains=$(domains_in "$home" || true)
		if [ -z "$domains" ]; then
			say_kv "域名" "还没有证书" warn
			echo
			continue
		fi
		while IFS= read -r domain; do
			[ -n "$domain" ] || continue
			print_one_cert "$home" "$domain" || true
			f=$(registered_install_paths "$home" "$domain" | tr '\n' ' ')
			if [ -n "$f" ]; then
				say_kv "登记安装" "$f" dim
			else
				say_kv "登记安装" "没有（Le_Real* 是空的）" dim
			fi
			f=""
			while IFS= read -r p; do
				[ -n "$p" ] || continue
				[ -f "$p" ] || continue
				path_under "$p" "$home" && continue
				path_protected "$p" && continue
				f="$f $p"
			done < <(old_cert_candidates "$domain" "$home")
			f=${f# }
			if [ -n "$f" ]; then
				say_kv "旧文件" "$f" warn
			fi
			echo
		done <<<"$domains"
	done <<<"$homes"
	say_dim "ACME_BIN 填托管目录，不是 acme.sh 这个文件。"
	say_dim "ACME_HOME 是证书库。默认安装时两者是同一个目录。"
	say_end
}

pick_home() {
	local homes=() h n reply
	while IFS= read -r h; do
		[ -n "$h" ] && homes+=("$h")
	done < <(discover_homes || true)
	if [ "${#homes[@]}" -eq 0 ]; then
		echo "没找到 acme 托管目录。" >&2
		return 1
	fi
	if [ "${#homes[@]}" -eq 1 ]; then
		printf '%s\n' "${homes[0]}"
		return 0
	fi
	echo "有多个托管目录：" >&2
	n=1
	for h in "${homes[@]}"; do
		echo "  $n) $h" >&2
		n=$((n + 1))
	done
	read -r -p "编号: " reply || return 1
	case "$reply" in
	'' | *[!0-9]*) echo "请输入数字。" >&2; return 1 ;;
	esac
	if [ "$reply" -lt 1 ] || [ "$reply" -gt "${#homes[@]}" ]; then
		echo "编号超出范围。" >&2
		return 1
	fi
	printf '%s\n' "${homes[$((reply - 1))]}"
}

pick_domain() {
	local home="$1" domains=() d n reply
	while IFS= read -r d; do
		[ -n "$d" ] && domains+=("$d")
	done < <(domains_in "$home")
	if [ "${#domains[@]}" -eq 0 ]; then
		if [ -n "$PRIMARY" ]; then
			printf '%s\n' "$PRIMARY"
			return 0
		fi
		echo "这个目录里没有证书。" >&2
		return 1
	fi
	if [ "${#domains[@]}" -eq 1 ]; then
		printf '%s\n' "${domains[0]}"
		return 0
	fi
	echo "有多张证书：" >&2
	n=1
	for d in "${domains[@]}"; do
		echo "  $n) $d" >&2
		n=$((n + 1))
	done
	read -r -p "编号: " reply || return 1
	case "$reply" in
	'' | *[!0-9]*) echo "请输入数字。" >&2; return 1 ;;
	esac
	if [ "$reply" -lt 1 ] || [ "$reply" -gt "${#domains[@]}" ]; then
		echo "编号超出范围。" >&2
		return 1
	fi
	printf '%s\n' "${domains[$((reply - 1))]}"
}

names_from_cert() {
	local cer="$1" names
	[ -f "$cer" ] || return 1
	command -v openssl >/dev/null 2>&1 || return 1
	names=$(openssl x509 -in "$cer" -noout -ext subjectAltName 2>/dev/null \
		| grep -oE 'DNS:[^, ]+' | sed 's/^DNS://' | awk '!seen[$0]++' | tr '\n' ' ' || true)
	names=${names% }
	[ -n "$names" ] || return 1
	printf '%s\n' "$names"
}

# 删掉登记在 Le_Real* 里、且不在托管目录 / 新部署目录中的证书文件，再把登记清空。
do_clear() {
	local home domain files=() f conf cleared=0
	need_tty || return 1
	need_root || return 1
	home=$(pick_home) || return 1
	domain=$(pick_domain "$home") || return 1
	echo "托管目录: $home"
	echo "域名:     $domain"
	echo "下面这些是 acme.sh 登记过的安装副本。托管目录里的原件不会动。"
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		if path_protected "$f" || path_under "$f" "$home"; then
			echo "  跳过（托管目录或新部署目录）: $f"
			continue
		fi
		if [ -f "$f" ]; then
			echo "  将删除: $f"
			files+=("$f")
		else
			echo "  登记了但文件已经不在: $f"
		fi
	done < <(registered_install_paths "$home" "$domain")
	if [ "${#files[@]}" -eq 0 ]; then
		echo "没有可删除的已安装副本。"
	fi
	if [ -f "/etc/ssl/${domain}.pem" ] || [ -f "/etc/ssl/${domain}.key" ]; then
		echo "/etc/ssl 里还有旧副本。这一步不删它们，用菜单 a。"
	fi
	confirm_no "清除这些已安装副本，并清空 Le_Real* 登记？" || {
		echo "已取消。"
		return 0
	}
	for f in "${files[@]}"; do
		rm -f -- "$f"
		echo "已删除 $f"
	done
	while IFS= read -r conf; do
		[ -n "$conf" ] || continue
		sed -i \
			-e "s|^Le_RealKeyPath=.*|Le_RealKeyPath=''|" \
			-e "s|^Le_RealFullChainPath=.*|Le_RealFullChainPath=''|" \
			-e "s|^Le_RealCertPath=.*|Le_RealCertPath=''|" \
			-e "s|^Le_RealCACertPath=.*|Le_RealCACertPath=''|" \
			"$conf"
		echo "已清空登记: $conf"
		cleared=1
	done < <(domain_confs "$home" "$domain")
	if [ "$cleared" -eq 0 ]; then
		echo "没有找到 ${domain}.conf，登记路径没改。"
	fi
}

do_write_conf() {
	local home owner bin_dir deploy http primary domains cer webroot body
	need_tty || return 1
	need_root || return 1
	home=$(pick_home) || return 1
	owner=$(stat -c '%U' "$home" 2>/dev/null || true)
	[ -n "$owner" ] && [ "$owner" != "root" ] || owner="${SUDO_USER:-${ACME_USER:-}}"
	if [ -z "$owner" ] || [ "$owner" = "root" ]; then
		owner=$(ask_default "业务用户" "") || return 1
	else
		owner=$(ask_default "业务用户" "$owner") || return 1
	fi
	[ -n "$owner" ] || {
		echo "用户不能空。" >&2
		return 1
	}
	bin_dir="$home"
	if [ ! -x "$home/acme.sh" ]; then
		bin_dir=$(ask_default "acme.sh 所在目录（里面有 acme.sh 文件）" "$home") || return 1
	fi
	bin_dir="${bin_dir%/}"
	if [ -f "$bin_dir" ] && [ "$(basename "$bin_dir")" = "acme.sh" ]; then
		bin_dir=$(dirname "$bin_dir")
	fi
	deploy=$(getent passwd "$owner" 2>/dev/null | cut -d: -f6 || true)
	[ -n "$deploy" ] || deploy="/home/$owner"
	webroot=""
	if [ -d "$deploy/nginx" ]; then
		webroot="$deploy/nginx"
	elif [ -d "$deploy/apache2" ]; then
		webroot="$deploy/apache2"
	fi
	deploy="${deploy}/cert"
	deploy=$(ask_default "部署目录（nginx 读的副本）" "$deploy") || return 1
	if systemctl is-active --quiet nginx 2>/dev/null; then
		http=nginx
	elif systemctl is-active --quiet apache2 2>/dev/null; then
		http=apache2
	else
		http=nginx
	fi
	http=$(ask_default "Web 服务 nginx / apache2 / none" "$http") || return 1
	case "$http" in
	nginx | apache2 | none | both) ;;
	*)
		echo "HTTP 只能是 nginx、apache2、none、both。" >&2
		return 1
		;;
	esac
	primary=$(pick_domain "$home" || true)
	primary=$(ask_default "主域名" "$primary") || return 1
	[ -n "$primary" ] || {
		echo "主域名不能空。" >&2
		return 1
	}
	cer=""
	cer=$(cert_dir_for "$home" "$primary" 2>/dev/null || true)
	domains=""
	if [ -n "$cer" ]; then
		domains=$(names_from_cert "$cer/fullchain.cer" || true)
	fi
	[ -n "$domains" ] || domains="$primary"
	domains=$(ask_default "全部域名（空格分开，主域名放最前）" "$domains") || return 1
	webroot=$(ask_default "校验目录（网站根目录）" "$webroot") || return 1

	echo
	echo "将写入 $CONF ："
	echo "  ACME_USER=$owner"
	echo "  ACME_BIN=$bin_dir"
	echo "  ACME_HOME=$home"
	echo "  DEPLOY_DIR=$deploy"
	echo "  HTTP=$http"
	echo "  PRIMARY=$primary"
	echo "  DOMAINS=$domains"
	echo "  WEBROOT=$webroot"
	confirm_no "写入？" || {
		echo "已取消。"
		return 0
	}
	if [ -f "$CONF" ]; then
		cp -a "$CONF" "${CONF}.bak"
		echo "旧文件已备份为 ${CONF}.bak"
	fi
	{
		printf 'ACME_USER=%q\n' "$owner"
		printf 'ACME_BIN=%q\n' "$bin_dir"
		printf 'ACME_HOME=%q\n' "$home"
		printf 'DEPLOY_DIR=%q\n' "$deploy"
		printf 'HTTP=%q\n' "$http"
		printf 'PRIMARY=%q\n' "$primary"
		printf 'DOMAINS=%q\n' "$domains"
		printf 'WEBROOT=%q\n' "$webroot"
	} >"$CONF"
	chmod 644 "$CONF"
	load_conf || true
	echo "已写入 $CONF"
	echo "部署用本目录的 acme-deploy-cert.sh。选菜单 5 时会把续签钩子改成这个文件，并写上免密。"
}

do_remove_old() {
	local home domain files=() f
	need_tty || return 1
	need_root || return 1
	home="${ACME_HOME:-}"
	if [ -z "$home" ]; then
		home=$(pick_home) || return 1
	fi
	domain="${PRIMARY:-}"
	if [ -z "$domain" ]; then
		domain=$(pick_domain "$home") || return 1
	else
		domain=$(ask_default "要清理旧文件的域名" "$domain") || return 1
	fi
	echo "只删除托管目录和新部署目录以外的旧副本。"
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		[ -f "$f" ] || continue
		if path_protected "$f" || path_under "$f" "$home"; then
			echo "  跳过: $f"
			continue
		fi
		echo "  将删除: $f"
		files+=("$f")
	done < <(old_cert_candidates "$domain" "$home" | awk '!seen[$0]++')
	if [ "${#files[@]}" -eq 0 ]; then
		echo "没有旧证书可删。"
		return 0
	fi
	confirm_no "删除上面这些旧文件？" || {
		echo "已取消。"
		return 0
	}
	for f in "${files[@]}"; do
		rm -f -- "$f"
		echo "已删除 $f"
	done
}

show_status() {
	local bin next conf pem info end days tone file line cron_ok=0 cron_any=0 domains domain count
	say_hdr "acme 状态"
	if [ ! -f "$CONF" ]; then
		say_kv "配置" "还没有 $CONF" warn
		say_dim "先 locate 查托管目录，再 write-conf / 菜单 9 生成配置。"
	else
		say_kv "配置" "$CONF" ok
	fi
	say_kv "用户" "${ACME_USER:-未知}" "${ACME_USER:+ok}"
	say_kv "主域名" "${PRIMARY:-未写}" "${PRIMARY:+info}"
	say_kv "证书域名" "${DOMAINS:-未写}" dim
	bin=$(acme_bin || true)
	if [ -n "$bin" ]; then
		say_kv "acme.sh" "$bin" ok
	else
		say_kv "acme.sh" "未安装" bad
	fi
	say_kv "托管目录" "${ACME_HOME:-未知}" info
	say_dim "（acme.sh 自己存的证书）"
	say_kv "部署目录" "${DEPLOY_DIR:-未知}" info
	say_dim "（nginx / apache 读这里）"

	pem=""
	if [ -n "$PRIMARY" ] && [ -n "$DEPLOY_DIR" ]; then
		pem="$DEPLOY_DIR/${PRIMARY}.pem"
	fi
	if [ -n "$pem" ] && [ -f "$pem" ]; then
		say_kv "已部署" "$pem" ok
		say_kv "密钥" "$DEPLOY_DIR/${PRIMARY}.key" dim
		if info=$(cert_expiry_line "$pem"); then
			IFS='|' read -r end days tone <<<"$info"
			if [ -n "$days" ]; then
				if [ "$days" -lt 0 ]; then
					say_kv "部署到期" "$end（已过期 $((-days)) 天）" bad
				else
					say_kv "部署到期" "$end（还剩 ${days} 天）" "$tone"
				fi
			else
				say_kv "部署到期" "$end" info
			fi
		fi
	else
		say_kv "已部署" "还没有 ${pem:-证书文件}" warn
	fi

	conf=""
	if [ -n "$PRIMARY" ] && [ -n "$ACME_HOME" ]; then
		conf=$(cert_conf "$PRIMARY" || true)
	fi
	next=""
	if [ -n "$conf" ]; then
		next=$(conf_field "$conf" Le_NextRenewTimeStr 2>/dev/null || conf_field "$conf" Le_NextRenewTime 2>/dev/null || true)
	fi
	say_kv "下次续签" "${next:-还没登记}" "${next:+info}"

	say_kv "Web 服务" "${HTTP:-未知}"
	say_kv "校验目录" "${WEBROOT:-未知}/.well-known/acme-challenge/" dim
	say_end

	# 托管证书摘要
	say_hdr "托管证书"
	count=0
	if [ -n "$ACME_HOME" ] && [ -d "$ACME_HOME" ]; then
		domains=$(domains_in "$ACME_HOME" || true)
		if [ -z "$domains" ]; then
			say_warn "托管目录里还没有证书"
		else
			while IFS= read -r domain; do
				[ -n "$domain" ] || continue
				print_one_cert "$ACME_HOME" "$domain" || true
				count=$((count + 1))
				echo
			done <<<"$domains"
			say_ok "合计 ${count} 张（详情: acme-ctl certs）"
		fi
	else
		say_warn "未配置 ACME_HOME。用 acme-ctl locate / certs 扫描。"
	fi
	say_end

	# cron：显示来源文件 + 整行
	say_hdr "自动续签（cron）"
	while IFS=$'\t' read -r file line; do
		[ -n "$line" ] || continue
		cron_any=1
		if printf '%s' "$line" | grep -qF -- '--cron'; then
			cron_ok=1
			say_kv "状态" "已开启（acme.sh --cron）" ok
		else
			say_kv "状态" "有 acme 相关行，但不是 --cron" warn
		fi
		say_kv "来源文件" "$file" info
		printf '  %s%-12s%s %s%s%s\n' "$_Cd" "crontab行" "$_C0" "$_Cb" "$line" "$_C0"
		echo
	done < <(collect_acme_cron | awk -F '\t' '!seen[$0]++')
	if [ "$cron_any" -eq 0 ]; then
		say_bad "没找到自动续签 cron"
		if [ -n "$ACME_USER" ]; then
			say_dim "应在用户 $ACME_USER 的 crontab 里"
			if file=$(cron_spool_path "$ACME_USER"); then
				say_dim "文件: $file"
			else
				say_dim "文件一般是: /var/spool/cron/crontabs/$ACME_USER"
			fi
			say_dim "查看: crontab -u $ACME_USER -l"
		fi
	elif [ "$cron_ok" -eq 0 ]; then
		say_warn "有相关行，但缺少 acme.sh --cron（续签可能不会自动跑）"
	fi
	say_dim "只看续签: acme-ctl cron"
	say_end

	echo
	printf '%s%s常用%s\n' "$_Cm" "$_Cb" "$_C0"
	say_dim "acme-ctl              状态 + 菜单"
	say_dim "acme-ctl status       只看状态"
	say_dim "acme-ctl certs        托管证书列表"
	say_dim "acme-ctl cron         自动续签与来源文件"
	say_dim "acme-ctl locate       查出托管目录和旧证书"
	say_kv "部署脚本" "$(deploy_helper 2>/dev/null || echo '本目录的 acme-deploy-cert.sh')" dim
}

# 优先用和 acme-ctl 放在一起的脚本，拷到哪就用哪。没有时才用检查点五装的 /usr/local/sbin。
deploy_helper() {
	local here
	here=$(cd "$(dirname "$0")" && pwd)
	if [ -f "$here/acme-deploy-cert.sh" ]; then
		chmod +x "$here/acme-deploy-cert.sh" 2>/dev/null || true
		if [ -x "$here/acme-deploy-cert.sh" ]; then
			printf '%s\n' "$here/acme-deploy-cert.sh"
			return 0
		fi
	fi
	if [ -x /usr/local/sbin/acme-deploy-cert ]; then
		printf '%s\n' /usr/local/sbin/acme-deploy-cert
		return 0
	fi
	return 1
}

# cron 以业务用户执行钩子，sudo 免密必须写成这个脚本的实际路径。
ensure_sudoers() {
	local helper="$1" user file
	[ "$(id -u)" -eq 0 ] || return 0
	user="${ACME_USER:-}"
	[ -n "$user" ] && [ -n "$helper" ] || return 0
	file=/etc/sudoers.d/acme-deploy-cert
	if [ -f "$file" ] && grep -qF "$helper" "$file"; then
		return 0
	fi
	cat >"$file" <<EOF
Defaults:${user} !requiretty
${user} ALL=(root) NOPASSWD: ${helper}
EOF
	chmod 440 "$file"
	if ! visudo -cf "$file" >/dev/null 2>&1; then
		echo "写入 sudoers 失败，已删除 $file" >&2
		rm -f "$file"
		return 1
	fi
	echo "已允许 $user 免密执行 $helper"
}

do_cron() {
	local bin
	[ -f "$CONF" ] || {
		echo "还没有 $CONF 。先生成配置。" >&2
		return 1
	}
	bin=$(acme_bin) || {
		echo "没有 acme.sh" >&2
		return 1
	}
	as_user "$bin" --home "${ACME_BIN:-$ACME_HOME}" --cron
}

do_deploy() {
	local helper cmd bin
	[ -f "$CONF" ] || {
		echo "还没有 $CONF 。先生成配置。" >&2
		return 1
	}
	helper=$(deploy_helper) || {
		echo "找不到 acme-deploy-cert.sh。它要和 acme-ctl.sh 放在同一个文件夹。" >&2
		return 1
	}
	ensure_sudoers "$helper" || true
	cmd=$(printf 'sudo -n %q' "$helper")
	if [ -n "$PRIMARY" ] && bin=$(acme_bin); then
		if as_user "$bin" --home "${ACME_BIN:-$ACME_HOME}" --install-cert -d "$PRIMARY" --reloadcmd "$cmd"; then
			echo "续签钩子已改为: $cmd"
			return 0
		fi
		echo "更新续签钩子失败，改为直接部署。" >&2
	fi
	if [ "$(id -u)" -eq 0 ]; then
		ACME_CONF="$CONF" "$helper" ${PRIMARY:+"$PRIMARY"}
		return
	fi
	sudo -n ACME_CONF="$CONF" "$helper" ${PRIMARY:+"$PRIMARY"}
}

do_issue() {
	local bin args d
	[ -f "$CONF" ] || {
		echo "还没有 $CONF 。先生成配置。" >&2
		return 1
	}
	bin=$(acme_bin) || {
		echo "没有 acme.sh" >&2
		return 1
	}
	if [ -z "$WEBROOT" ] || [ ! -d "$WEBROOT" ]; then
		echo "校验目录不存在: ${WEBROOT:-空}" >&2
		return 1
	fi
	args=(--issue --force)
	for d in $DOMAINS; do
		args+=(-d "$d")
	done
	args+=(-w "$WEBROOT")
	echo "将签发: $DOMAINS"
	echo "校验目录: $WEBROOT"
	echo "已有域名密钥，使用 --force 覆盖重签。"
	as_user "$bin" --home "${ACME_BIN:-$ACME_HOME}" "${args[@]}"
	local rc=$?
	if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
		return "$rc"
	fi
	do_deploy
}

menu() {
	local choice
	while true; do
		show_status
		printf '\n%s%s菜单%s\n' "$_Cm" "$_Cb" "$_C0"
		printf '  %s1)%s 再看一次状态\n' "$_Cc" "$_C0"
		printf '  %s2)%s 列出托管证书（到期 / SAN / 续签钩子）\n' "$_Cc" "$_C0"
		printf '  %s3)%s 查看自动续签 cron（来源文件 + 内容）\n' "$_Cc" "$_C0"
		printf '  %s4)%s 按 cron 方式续签（acme.sh --cron）\n' "$_Cy" "$_C0"
		printf '  %s5)%s 把证书部署到 %s 并 reload\n' "$_Cy" "$_C0" "${DEPLOY_DIR:-~/cert}"
		printf '  %s6)%s 按配置重新签发（主域名 + SAN）\n' "$_Cy" "$_C0"
		printf '  %s7)%s 查出 acme 托管目录和旧证书\n' "$_Cc" "$_C0"
		printf '  %s8)%s 清除已安装副本（不动托管原件）\n' "$_Cr" "$_C0"
		printf '  %s9)%s 生成 %s\n' "$_Cg" "$_C0" "$CONF"
		printf '  %sa)%s 删除旧位置证书（不动托管/部署目录）\n' "$_Cr" "$_C0"
		printf '  %sq)%s 退出\n' "$_Cd" "$_C0"
		read -r -p "请选择 [1-9/a/q]: " choice || exit 0
		case "$choice" in
		1 | "") ;;
		2) show_certs || true ;;
		3) show_cron || true ;;
		4) do_cron || true ;;
		5) do_deploy || true ;;
		6) do_issue || true ;;
		7) show_locate || true ;;
		8) do_clear || true ;;
		9) do_write_conf || true ;;
		a | A) do_remove_old || true ;;
		q | Q) exit 0 ;;
		*) printf '%s请输入 1-9、a 或 q。%s\n' "$_Cy" "$_C0" ;;
		esac
		echo
	done
}

usage() {
	echo "用法: acme-ctl [status|certs|cron|locate|clear|write-conf|deploy|remove-old]" >&2
	echo "无参数：终端里进菜单。迁移按 7 → 8 → 9 → 5 → a 自己做。" >&2
}

case "${1:-}" in
status | --status | -s)
	show_status
	;;
certs | cert | list)
	show_certs
	;;
cron)
	show_cron || true
	;;
locate)
	show_locate
	;;
clear)
	do_clear
	;;
write-conf)
	do_write_conf
	;;
deploy)
	do_deploy
	;;
remove-old)
	do_remove_old
	;;
"")
	if [ -t 0 ]; then
		menu
	else
		show_status
	fi
	;;
-h | --help | help)
	usage
	;;
*)
	usage
	exit 2
	;;
esac

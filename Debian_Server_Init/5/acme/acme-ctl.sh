#!/bin/bash
# 交互查看 / 迁移 acme.sh。没有 /etc/acme-deploy.conf 也能先查托管目录、再生成配置。
# 安装后：acme-ctl
# 只看状态：acme-ctl status
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

need_tty() {
	if [ -t 0 ]; then
		return 0
	fi
	echo "这一步要在终端里确认。" >&2
	return 1
}

need_root() {
	if [ "$(id -u)" -eq 0 ]; then
		return 0
	fi
	echo "请用 root 运行这一步。" >&2
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

show_locate() {
	local homes home owner domains domain cdir f p
	echo
	echo "======== acme 托管位置 ========"
	homes=$(discover_homes || true)
	if [ -z "$homes" ]; then
		echo "没找到 acme.sh 目录。常见位置是 /home/用户/.acme.sh"
		echo "==============================="
		return 1
	fi
	while IFS= read -r home; do
		[ -n "$home" ] || continue
		owner=$(stat -c '%U' "$home" 2>/dev/null || echo 未知)
		echo "托管目录    $home"
		echo "属主        $owner"
		if [ -x "$home/acme.sh" ]; then
			echo "程序        $home/acme.sh"
		else
			echo "程序        这个目录里没有 acme.sh（可能只是证书库）"
		fi
		domains=$(domains_in "$home" || true)
		if [ -z "$domains" ]; then
			echo "域名        还没有证书"
			echo
			continue
		fi
		while IFS= read -r domain; do
			[ -n "$domain" ] || continue
			cdir=$(cert_dir_for "$home" "$domain" || true)
			echo "域名        $domain"
			echo "  库存      ${cdir:-未知}/fullchain.cer"
			f=$(registered_install_paths "$home" "$domain" | tr '\n' ' ')
			if [ -n "$f" ]; then
				echo "  登记安装  $f"
			else
				echo "  登记安装  没有（Le_Real* 是空的）"
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
				echo "  旧文件    $f"
			fi
		done <<<"$domains"
		echo
	done <<<"$homes"
	echo "ACME_BIN 填托管目录，不是 acme.sh 这个文件。"
	echo "ACME_HOME 是证书库。默认安装时两者是同一个目录。"
	echo "==============================="
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
		echo "/etc/ssl 里还有旧副本。这一步不删它们，用菜单 8。"
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
	echo "部署用本目录的 acme-deploy-cert.sh。选菜单 3 时会把续签钩子改成这个文件，并写上免密。"
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
	local bin cron next expire san conf pem
	echo
	echo "======== acme 状态 ========"
	if [ ! -f "$CONF" ]; then
		echo "配置        还没有 $CONF"
		echo "先用菜单查出托管目录，再生成这份配置。部署和续签要等它写好。"
	else
		echo "配置        $CONF"
	fi
	echo "用户        ${ACME_USER:-未知}"
	echo "主域名      ${PRIMARY:-未写}"
	echo "证书域名    ${DOMAINS:-未写}"
	bin=$(acme_bin || true)
	if [ -n "$bin" ]; then
		echo "acme.sh     $bin"
	else
		echo "acme.sh     未安装"
	fi
	echo "托管目录    ${ACME_HOME:-未知}    （acme.sh 自己存的证书）"
	echo "部署目录    ${DEPLOY_DIR:-未知}    （nginx / apache 读这里）"
	pem=""
	if [ -n "$PRIMARY" ] && [ -n "$DEPLOY_DIR" ]; then
		pem="$DEPLOY_DIR/${PRIMARY}.pem"
	fi
	if [ -n "$pem" ] && [ -f "$pem" ]; then
		echo "已部署      $pem"
		echo "密钥        $DEPLOY_DIR/${PRIMARY}.key"
		if command -v openssl >/dev/null 2>&1; then
			expire=$(openssl x509 -in "$pem" -noout -enddate -dateopt iso_8601 2>/dev/null || openssl x509 -in "$pem" -noout -enddate 2>/dev/null || true)
			san=$(openssl x509 -in "$pem" -noout -ext subjectAltName 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g' || true)
			echo "到期        ${expire:-读不到}"
			[ -n "$san" ] && echo "SAN         $san"
		fi
	else
		echo "已部署      还没有 ${pem:-证书文件}"
	fi

	conf=""
	if [ -n "$PRIMARY" ] && [ -n "$ACME_HOME" ]; then
		conf=$(cert_conf "$PRIMARY" || true)
	fi
	next=""
	if [ -n "$conf" ]; then
		next=$(sed -n 's/^Le_NextRenewTimeStr=//p' "$conf" | head -n 1 | tr -d "'\"")
		[ -n "$next" ] || next=$(sed -n 's/^Le_NextRenewTime=//p' "$conf" | head -n 1 | tr -d "'\"")
	fi
	echo "下次续签    ${next:-还没登记}"

	cron=""
	if [ -n "$ACME_USER" ]; then
		cron=$(as_user crontab -l 2>/dev/null | grep -F 'acme.sh' | grep -F -- '--cron' || true)
	fi
	if [ -n "$cron" ]; then
		echo "自动续签    有（用户 crontab 里的 acme.sh --cron）"
	else
		echo "自动续签    没找到。安装 acme.sh 时会给业务用户写一条 cron。"
	fi
	echo "Web 服务    ${HTTP:-未知}"
	echo "校验目录    ${WEBROOT:-未知}/.well-known/acme-challenge/"
	echo "==========================="
	echo
	echo "常用："
	echo "  acme-ctl                  看状态并进入菜单"
	echo "  acme-ctl status           只看状态"
	echo "  acme-ctl locate           查出托管目录和旧证书"
	echo "  部署脚本    $(deploy_helper 2>/dev/null || echo '本目录的 acme-deploy-cert.sh')"
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
		echo "  1) 再看一次状态"
		echo "  2) 按 cron 的方式续签（acme.sh --cron）"
		echo "  3) 把证书再部署到 ${DEPLOY_DIR:-~/cert} 并 reload"
		echo "  4) 按配置重新签发（主域名 + SAN）"
		echo "  5) 查出 acme 托管目录和旧证书"
		echo "  6) 清除已安装副本（不动托管目录里的原件）"
		echo "  7) 生成 $CONF"
		echo "  8) 删除旧位置的证书（不动托管目录和部署目录）"
		echo "  q) 退出"
		read -r -p "请选择 [1-8/q]: " choice || exit 0
		case "$choice" in
		1 | "") ;;
		2) do_cron || true ;;
		3) do_deploy || true ;;
		4) do_issue || true ;;
		5) show_locate || true ;;
		6) do_clear || true ;;
		7) do_write_conf || true ;;
		8) do_remove_old || true ;;
		q | Q) exit 0 ;;
		*) echo "请输入 1 到 8 或 q。" ;;
		esac
		echo
	done
}

usage() {
	echo "用法: acme-ctl [status|locate|clear|write-conf|deploy|remove-old]" >&2
	echo "无参数：终端里进菜单。迁移不要一键，按 5 → 6 → 7 → 3 → 8 自己做。" >&2
}

case "${1:-}" in
status | --status | -s)
	show_status
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

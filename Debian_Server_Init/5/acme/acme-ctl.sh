#!/bin/bash
# 交互查看 acme.sh：托管位置、部署目录、自动续签、到期时间。
# 安装后：acme-ctl
# 只看状态：acme-ctl status
CONF="${ACME_CONF:-/etc/acme-deploy.conf}"

if [ ! -f "$CONF" ]; then
	echo "找不到 $CONF 。先跑过 Debian_Server_Init 的检查点五（安装 acme.sh）。" >&2
	exit 1
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
_home=""
if [ -n "$ACME_USER" ]; then
	_home=$(getent passwd "$ACME_USER" 2>/dev/null | cut -d: -f6 || true)
fi
if [ -z "${DEPLOY_DIR:-}" ] && [ -n "$_home" ]; then
	DEPLOY_DIR="${_home}/cert"
fi

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

show_status() {
	local bin cron next expire san conf pem
	echo
	echo "======== acme 状态 ========"
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
	if [ -n "$PRIMARY" ]; then
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
		echo "自动续签    没找到。安装 acme.sh 时会给 $ACME_USER 写一条 cron。"
	fi
	echo "Web 服务    ${HTTP:-未知}"
	echo "校验目录    ${WEBROOT:-未知}/.well-known/acme-challenge/"
	echo "==========================="
	echo
	echo "常用："
	echo "  acme-ctl                  看状态并进入菜单"
	echo "  acme-ctl status           只看状态"
	echo "  sudo -n /usr/local/sbin/acme-deploy-cert    再拷一次到部署目录"
}

do_cron() {
	local bin
	bin=$(acme_bin) || {
		echo "没有 acme.sh" >&2
		return 1
	}
	as_user "$bin" --home "${ACME_BIN:-$ACME_HOME}" --cron
}

do_deploy() {
	if [ "$(id -u)" -eq 0 ]; then
		/usr/local/sbin/acme-deploy-cert ${PRIMARY:+"$PRIMARY"}
		return
	fi
	sudo -n /usr/local/sbin/acme-deploy-cert ${PRIMARY:+"$PRIMARY"}
}

do_issue() {
	local bin args d
	bin=$(acme_bin) || {
		echo "没有 acme.sh" >&2
		return 1
	}
	if [ -z "$WEBROOT" ] || [ ! -d "$WEBROOT" ]; then
		echo "校验目录不存在: ${WEBROOT:-空}" >&2
		return 1
	fi
	args=(--issue)
	for d in $DOMAINS; do
		args+=(-d "$d")
	done
	args+=(-w "$WEBROOT")
	echo "将签发: $DOMAINS"
	echo "校验目录: $WEBROOT"
	as_user "$bin" --home "${ACME_BIN:-$ACME_HOME}" "${args[@]}"
	local rc=$?
	if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
		return "$rc"
	fi
	as_user "$bin" --home "${ACME_BIN:-$ACME_HOME}" --install-cert -d "$PRIMARY" \
		--reloadcmd "sudo -n /usr/local/sbin/acme-deploy-cert" || true
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
		echo "  q) 退出"
		read -r -p "请选择 [1/2/3/4/q]: " choice || exit 0
		case "$choice" in
		1 | "") ;;
		2) do_cron || true ;;
		3) do_deploy || true ;;
		4) do_issue || true ;;
		q | Q) exit 0 ;;
		*) echo "请输入 1、2、3、4 或 q。" ;;
		esac
	done
}

case "${1:-}" in
status | --status | -s)
	show_status
	;;
"")
	if [ -t 0 ]; then
		menu
	else
		show_status
	fi
	;;
*)
	echo "用法: acme-ctl [status]" >&2
	exit 2
	;;
esac

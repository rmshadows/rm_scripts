#!/usr/bin/env bash
# 生成部署用登录账号（用户名+强密码），写入 .deploy_credentials
# 用法:
#   bash gen_credentials.sh           # 没有文件就生成；已有则只显示用户名
#   bash gen_credentials.sh --force   # 重新生成
#   bash gen_credentials.sh --show    # 显示已保存的用户名和密码
#   bash gen_credentials.sh --manual  # 自己输入（不要用 admin/passwd）
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEPLOY_SCRIPT_ROOT="$ROOT"
# shellcheck source=Lib.sh
source "$ROOT/Lib.sh"

usage() {
	cat <<EOF
用法: $(basename "$0") [--force|--show|--manual|--help]

默认自动生成一组登录账号，写入:
  $ROOT/.deploy_credentials

之后跑 Debian_13_Server_Setup.sh 会自动读这个文件，不必再手输。

  --force    丢掉旧文件，重新生成
  --show     打印已保存的用户名和密码
  --manual   自己输入用户名和密码
EOF
}

CRED_FILE=$(cred_file_path)

case "${1:-}" in
"" ) ;;
--force | -f) SET_CREDENTIALS_FORCE=1 ;;
--show)
	if [ ! -f "$CRED_FILE" ]; then
		prompt -e "还没有 $CRED_FILE ，先运行: bash gen_credentials.sh"
		exit 1
	fi
	# shellcheck disable=SC1090
	source "$CRED_FILE"
	cred_print_login "$SET_USER_NAME" "$SET_USER_PASSWD" "$CRED_FILE"
	exit 0
	;;
--manual | -m) SET_CREDENTIALS_MANUAL=1 ;;
-h | --help | help)
	usage
	exit 0
	;;
*)
	prompt -e "未知参数: $1"
	usage
	exit 1
	;;
esac

if [ -f "$CRED_FILE" ] && [ "${SET_CREDENTIALS_FORCE:-0}" -ne 1 ] && [ "${SET_CREDENTIALS_MANUAL:-0}" -ne 1 ]; then
	# shellcheck disable=SC1090
	source "$CRED_FILE"
	prompt -s "已有账号文件，不覆盖（要换一组请加 --force）"
	prompt -k "用户名：" "$SET_USER_NAME"
	prompt -k "文件：" "$CRED_FILE"
	prompt -m "看密码: bash gen_credentials.sh --show"
	exit 0
fi

if [ "${SET_CREDENTIALS_MANUAL:-0}" -eq 1 ]; then
	cred_prompt_manual
else
	SET_USER_NAME=$(cred_generate_username)
	SET_USER_PASSWD=$(cred_generate_password)
fi

if cred_username_is_weak "$SET_USER_NAME" || cred_password_is_weak "$SET_USER_PASSWD" "$SET_USER_NAME"; then
	prompt -e "结果仍过弱，未写入"
	exit 1
fi

cred_save_file "$CRED_FILE" "$SET_USER_NAME" "$SET_USER_PASSWD"
if [ "$(id -u)" -eq 0 ]; then
	cred_save_file "/root/.debian_server_init_login" "$SET_USER_NAME" "$SET_USER_PASSWD"
fi
cred_print_login "$SET_USER_NAME" "$SET_USER_PASSWD" "$CRED_FILE"
prompt -s "下一步: bash Debian_13_Server_Setup.sh"

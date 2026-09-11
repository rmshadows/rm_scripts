#!/usr/bin/env bash
# 生成部署用登录账号（用户名+强密码），写入 .deploy_credentials
# 用法:
#   bash gen_credentials.sh           # 没有文件则询问：自动生成或自己输入
#   bash gen_credentials.sh --force   # 丢掉旧文件，再询问
#   bash gen_credentials.sh --auto    # 不询问，直接自动生成
#   bash gen_credentials.sh --manual  # 不询问，自己输入
#   bash gen_credentials.sh --show    # 显示已保存的用户名和密码
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEPLOY_SCRIPT_ROOT="$ROOT"
# shellcheck source=Lib.sh
source "$ROOT/Lib.sh"

usage() {
	cat <<EOF
用法: $(basename "$0") [--force] [--auto|--manual] [--show] [--help]

写入:
  $ROOT/.deploy_credentials

之后跑 Debian_13_Server_Setup.sh 会自动读这个文件。

  --force    丢掉旧文件再生成/输入
  --auto     不询问，自动生成
  --manual   不询问，自己输入（不要用 admin/passwd）
  --show     打印已保存的用户名和密码
EOF
}

CRED_FILE=$(cred_file_path)
SET_CREDENTIALS_FORCE=0
SET_CREDENTIALS_SHOW=0

while [ $# -gt 0 ]; do
	case "$1" in
	--force | -f) SET_CREDENTIALS_FORCE=1 ;;
	--show)
		SET_CREDENTIALS_SHOW=1
		;;
	--manual | -m) SET_CREDENTIALS_MANUAL=1 ;;
	--auto | -a) SET_CREDENTIALS_AUTO=1 ;;
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
	shift
done

if [ "$SET_CREDENTIALS_SHOW" -eq 1 ]; then
	if [ ! -f "$CRED_FILE" ]; then
		prompt -e "还没有 $CRED_FILE ，先运行: bash gen_credentials.sh"
		exit 1
	fi
	# shellcheck disable=SC1090
	source "$CRED_FILE"
	cred_print_login "$SET_USER_NAME" "$SET_USER_PASSWD" "$CRED_FILE"
	exit 0
fi

if [ -f "$CRED_FILE" ] && [ "${SET_CREDENTIALS_FORCE:-0}" -ne 1 ] && [ "${SET_CREDENTIALS_MANUAL:-0}" -ne 1 ]; then
	# shellcheck disable=SC1090
	source "$CRED_FILE"
	prompt -s "已有账号文件，不覆盖（要换一组请加 --force）"
	prompt -k "用户名：" "$SET_USER_NAME"
	prompt -k "文件：" "$CRED_FILE"
	prompt -m "看密码: bash gen_credentials.sh --show"
	exit 0
fi

cred_choose_mode
if [ "$CRED_MODE" = manual ]; then
	cred_prompt_manual
else
	cred_generate_pair || {
		prompt -e "自动生成失败"
		exit 1
	}
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

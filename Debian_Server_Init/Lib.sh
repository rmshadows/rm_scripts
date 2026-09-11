#!/bin/bash
: <<!说明
这里是函数库
依赖 GlobalVariables.sh
2025年 02月 12日 星期三 09:49:37 CST
!说明

#### 脚本内置函数调用

## 控制台颜色输出
# 红色：警告、重点
# 黄色：警告、一般打印
# 绿色：执行日志
# 蓝色、白色：常规信息
# 颜色colors
CDEF=" \033[0m"      # default color
CCIN=" \033[0;36m"   # info color
CGSC=" \033[0;32m"   # success color
CRER=" \033[0;31m"   # error color
CWAR=" \033[0;33m"   # warning color
b_CDEF=" \033[1;37m" # bold default color
b_CCIN=" \033[1;36m" # bold info color
b_CGSC=" \033[1;32m" # bold success color
b_CRER=" \033[1;31m" # bold error color
b_CWAR=" \033[1;33m"
# echo like ...  with  flag type  and display message  colors
# -s 绿
# -e 红
# -w 黄
# -i 蓝
prompt() {
	case ${1} in
	"-s" | "--success")
		echo -e "${b_CGSC}${@/-s/}${CDEF}"
		;; # print success message
	"-x" | "--exec")
		echo -e "日志：${b_CGSC}${@/-x/}${CDEF}"
		;; # print exec message
	"-e" | "--error")
		echo -e "${b_CRER}${@/-e/}${CDEF}"
		;; # print error message
	"-w" | "--warning")
		echo -e "${b_CWAR}${@/-w/}${CDEF}"
		;; # print warning message
	"-i" | "--info")
		echo -e "${b_CCIN}${@/-i/}${CDEF}"
		;; # print info message
	"-m" | "--msg")
		echo -e "信息：${b_CCIN}${@/-m/}${CDEF}"
		;;                                                 # print iinfo message
	"-k" | "--kv")                                      # 三个参数
		echo -e "${b_CCIN} ${2} ${b_CWAR} ${3} ${CDEF}" ;; # print success message
	*)
		echo -e "$@"
		;;
	esac
}

# 如果用户按下Ctrl+c
trap "onSigint" SIGINT

# 程序中断处理方法,包含正常退出该执行的代码
onSigint() {
	prompt -w "捕获到 Ctrl + C 中断信号..."
	onExit # TODO:中断后恢复正常退出的方法
	exit 1
}

# 正常退出需要执行的
onExit() {
	cancelTempSudoer
}

# 中途异常退出脚本要执行的 注意，检查点一后才能使用这个方法
quitThis() {
	onExit
	exit
}

beTempSudoer() {
	prompt -x "临时成为免密码sudoer……"
	# 临时加入sudoer所使用的语句
	TEMPORARILY_SUDOER_STRING="$USER ALL=(ALL)NOPASSWD:ALL"
	# 临时成为sudo用户
	# doAsRoot "echo '$TEMPORARILY_SUDOER_STRING' >> /etc/sudoers"
	doAsRoot "echo '$TEMPORARILY_SUDOER_STRING' > /etc/sudoers.d/temp_sudo"
}

cancelTempSudoer() {
	# 临时加入sudoer，退出时清除
	if [ $TEMPORARILY_SUDOER -eq 1 ]; then
		prompt -x "清除临时sudoer免密权限。"
		doAsRoot "rm /etc/sudoers.d/temp_sudo"
		if [ "$?" -ne 0 ]; then
			prompt -e "警告：未知错误，请手动删除 /etc/sudoers.d/temp_sudo "
		fi
		# # 获取最后一行
		# tail_sudo=$(sudo tail -n 1 /etc/sudoers)
		# if [ "$tail_sudo" = "$TEMPORARILY_SUDOER_STRING" ] >/dev/null; then
		#   # 删除最后一行
		#   sudo sed -i '$d' /etc/sudoers
		# else
		#   # 一般不会出现这个情况吧。。
		#   prompt -e "警告：未知错误，请手动删除 $TEMPORARILY_SUDOER_STRING "
		#   exit 1
		# fi
	fi
}

# 以root身份运行
# 工作目录:/root
doAsRoot() {
	# 如果当前是 root 用户，直接执行命令
	if [ "$(whoami)" == "root" ]; then
		eval "$1"
		return
	fi
	# 如果没有定义 root 密码且当前用户不是 sudo 用户，提示输入密码
	if [ -z "$ROOT_PASSWD" ] && [ "$IS_SUDOER" -ne 1 ]; then
		prompt -w "未在脚本里定义root用户密码，请输入root用户密码: "
		read -r input
		ROOT_PASSWD=$input
	fi
	# 检查 root 密码的有效性
	checkRootPasswd
	# 如果当前用户不是 root，切换为 root 用户执行命令
	echo "当前不是 root，正在切换为 root 用户..."
	echo "$ROOT_PASSWD" | su -c "$1" -l
}

# 检查root密码是否正确
checkRootPasswd() {
	# 下面不能有缩进！
	su - root <<! >/dev/null 2>/dev/null
$ROOT_PASSWD
pwd
!
	# echo $?
	if [ "$?" -ne 0 ]; then
		prompt -e "Root 用户密码不正确！"
		exit 1
	fi
}

## 询问函数 Yes:1 No:2 ???:5
: <<!询问函数
函数调用请使用：
comfirm "\e[1;33m? [y/N]\e[0m"
choice=$?
if [ $choice == 1 ];then
  yes
elif [ $choice == 2 ];then
  prompt -i "——————————  下一项  ——————————"
else
  prompt -e "ERROR:未知返回值!"
  exit 5
fi
!询问函数
comfirm() {
	flag=true
	ask=$1
	while $flag; do
		echo -e "$ask"
		read -r input
		if [ -z "${input}" ]; then
			# 默认选择N
			input='n'
		fi
		case $input in [yY][eE][sS] | [yY])
			return 1
			flag=false
			;;
		[nN][oO] | [nN])
			return 2
			flag=false
			;;
		*)
			prompt -w "Invalid option..."
			;;
		esac
	done
}

# 备份配置文件。先检查是否有bak结尾的备份文件，没有则创建，有则另外覆盖一个newbak文件。$1 :文件名
backupFile() {
	if [ -e "$1" ]; then
		# 如果是文件或目录，判断备份情况
		if [ -e "$1.bak" ]; then
			# 如果存在.bak备份，创建.newbak覆盖备份
			prompt -x "(sudo)正在备份 $1 到 $1.newbak (覆盖)"
			sudo cp -r "$1" "$1.newbak"
		else
			# 如果没有.bak备份，创建.bak备份
			prompt -x "(sudo)正在备份 $1 到 $1.bak"
			sudo cp -r "$1" "$1.bak"
		fi
	else
		# 如果目标文件或目录不存在
		prompt -e "没有 $1，不做备份"
	fi
}

# 交互式安装（apt-listchanges / pager / debconf 等）必须连真实 TTY。
# 管道、tee、未 flush 的 script 都会让界面画不出来、按键进不去。
deploy_tty_ok() {
	[ -t 0 ] && [ -t 1 ] && [ -t 2 ]
}

deploy_prepare_interactive() {
	if ! deploy_tty_ok; then
		prompt -e "stdin/stdout/stderr 不是终端。debconf / pager / ncurses 无法显示，也无法接收按键。"
		prompt -w "请直接在终端运行：bash Debian_13_Server_Setup.sh（不要再套一层管道或无 -t 的 ssh）"
		return 1
	fi
	if [ -z "${DEBIAN_FRONTEND:-}" ] || [ "${DEBIAN_FRONTEND}" = "noninteractive" ]; then
		if command -v whiptail >/dev/null 2>&1 || command -v dialog >/dev/null 2>&1; then
			export DEBIAN_FRONTEND=dialog
		else
			export DEBIAN_FRONTEND=readline
		fi
	fi
	export TERM="${TERM:-xterm-256color}"
	return 0
}

# 执行apt命令 注意，检查点一后才能使用这个方法
doApt() {
	prompt -x "doApt: $@"
	# 仅本机第一次跑部署时提示一次（unattended-upgrade 可能占锁）。续跑/再跑不再 sleep。
	if [ "${FIRST_DO_APT:-1}" -eq 1 ]; then
		FIRST_DO_APT=0
		_apt_hint="${DEPLOY_SCRIPT_ROOT:-.}/.deploy_apt_hint"
		if [ ! -f "$_apt_hint" ]; then
			prompt -w "如果APT显示被占用，『对此的通常建议是等待』（unattended-upgrade 等）。如果你没有耐心，请尝试根据报错决定是否运行下列所示的命令(删锁、dpkg重配置)，注意：后者是极不建议的！"
			prompt -e "sudo rm /var/lib/dpkg/lock-frontend && sudo rm /var/lib/dpkg/lock && sudo dpkg --configure -a"
			sleep 5
			echo 1 >"$_apt_hint" 2>/dev/null || true
		fi
	fi
	if [ "$1" = "install" ] || [ "$1" = "remove" ] || [ "$1" = "purge" ] || [ "$1" = "dist-upgrade" ] || [ "$1" = "upgrade" ] || [ "$1" = "full-upgrade" ]; then
		deploy_prepare_interactive || prompt -w "无 TTY，debconf 问答可能无法操作"
	fi
	# sudo 默认 env_reset，不把 DEBIAN_FRONTEND 传下去则对话框出不来
	local _sudo=(sudo --preserve-env=DEBIAN_FRONTEND,DEBCONF_FRONTEND,TERM,LANG,LC_ALL,LANGUAGE,DISPLAY)
	if [ "$1" = "install" ] || [ "$1" = "remove" ] || [ "$1" = "purge" ] || [ "$1" = "dist-upgrade" ] || [ "$1" = "upgrade" ] || [ "$1" = "full-upgrade" ]; then
		if [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 0 ]; then
			"${_sudo[@]}" apt "$@"
		elif [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 1 ]; then
			"${_sudo[@]}" apt "$@" -y
		fi
	else
		"${_sudo[@]}" apt "$@"
	fi
}

# 新建文件夹 $1
addFolder() {
	if [ $# -ne 1 ]; then
		prompt -e "addFolder () 只能有一个参数"
		quitThis
	fi
	if ! [ -d "$1" ]; then
		prompt -x "新建文件夹 $1 "
		install -d "$1"
	fi
	if ! [ -d "$1" ]; then
		prompt -x "(sudo)新建文件夹 $1 "
		sudo install -d "$1"
	fi
}

# 后台记录日志 log_message_bg "信息" "日志文件"
log_message_bg() {
	local message="$1"
	local log_file="$2"
	# 检查日志路径是否为空或不可写
	if [ -z "$log_file" ]; then
		echo "Error: Log file path is not specified." >&2
		return 1
	fi
	# 写入日志，文件不存在时自动创建
	{
		echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
	} >>"$log_file" || {
		echo "Error: Failed to write to log file '$log_file'." >&2
		return 1
	}
}

# 记录日志(会显示再终端) log_message_bg "信息" "日志文件"
log_message() {
	local message="$1"
	local log_file="$2"
	# 检查日志路径是否为空或不可写
	if [ -z "$log_file" ]; then
		echo "Error: Log file path is not specified." >&2
		return 1
	fi
	# 写入日志，文件不存在时自动创建
	{
		local lmsg="【 $(date '+%Y-%m-%dT%H:%M:%S') 】- $message"
		# 输出在终端并写入日志文件
		echo "$lmsg" | tee -a "$log_file" # 使用 tee 输出到终端并写入文件
	} || {
		echo "Error: Failed to write to log file '$log_file'." >&2
		return 1
	}
}

# 执行脚本（日志+输出） do_job "setup.sh" "$ELOG_FILE"
: <<!说明
# 原本是这样:
cd 1
log_message "日志：任务开始 - setup.sh" "$ELOG_FILE"
# source "setup.sh" 2>&1 | tee -a "$ELOG_FILE"  # 将输出记录到日志文件
{
    # 通过进程替换处理标准错误，逐行读取并加上 [stderr]
    source "setup.sh" 2> >(while IFS= read -r line; do echo -e " \033[1;31;47m [stderr] \033[0m $line"; done) | 
    while IFS= read -r line; do
        echo "[stdout] $line"    # 处理标准输出，逐行加上 [stdout]
    done
} | tee -a "$ELOG_FILE"    # 将输出追加到日志文件
log_message "日志：任务结束 - 1/setup.sh" "$ELOG_FILE"
cd ..
# 管道会抢走 TTY：apt modernize-sources / pager / debconf 会卡住等回车。
!说明

# ---------- 部署进度（失败后续跑） ----------
deploy_job_key() {
	local script="$1"
	local current_dir
	current_dir=$(pwd)
	if [ -n "$DEPLOY_SCRIPT_ROOT" ] && [[ "$current_dir" == "$DEPLOY_SCRIPT_ROOT"* ]]; then
		echo "${current_dir#"$DEPLOY_SCRIPT_ROOT"/}/$(basename "$script")"
	else
		echo "$(basename "$current_dir")/$(basename "$script")"
	fi
}

deploy_is_job_done() {
	local job_key="$1"
	[ -f "$DEPLOY_STATE_FILE" ] && grep -Fxq "$job_key" "$DEPLOY_STATE_FILE"
}

deploy_mark_job_done() {
	local job_key="$1"
	mkdir -p "$(dirname "$DEPLOY_STATE_FILE")" 2>/dev/null || true
	if ! deploy_is_job_done "$job_key"; then
		echo "$job_key" >>"$DEPLOY_STATE_FILE"
	fi
}

deploy_reset_state() {
	rm -f "$DEPLOY_STATE_FILE"
}

deploy_unmark_job() {
	local job_key="$1"
	local tmp
	[ -f "$DEPLOY_STATE_FILE" ] || return 0
	tmp=$(mktemp)
	grep -Fxv "$job_key" "$DEPLOY_STATE_FILE" >"$tmp" || true
	mv "$tmp" "$DEPLOY_STATE_FILE"
}

# ---------- 默认账号过弱：自动生成用户名/密码 ----------
# Config 占位 admin/passwd 上过公网爆破（Vultr 等会直接关机）。
# 没有现成账号时：终端里选 1=自动生成 / 2=自己输入。
# 跳过菜单：SET_CREDENTIALS_AUTO=1 或 SET_CREDENTIALS_MANUAL=1。

cred_file_path() {
	echo "${DEPLOY_SCRIPT_ROOT:-.}/.deploy_credentials"
}

cred_username_is_weak() {
	local u
	u=$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')
	case "$u" in
	admin | administrator | user | test | debian | ubuntu | guest | linux | server | root | passwd)
		return 0
		;;
	esac
	return 1
}

cred_password_is_weak() {
	local p="${1:-}"
	local u
	u=$(printf '%s' "${2:-}" | tr '[:upper:]' '[:lower:]')
	local pl
	pl=$(printf '%s' "$p" | tr '[:upper:]' '[:lower:]')
	[ -z "$p" ] && return 0
	[ "${#p}" -lt 8 ] && return 0
	[ -n "$u" ] && [ "$pl" = "$u" ] && return 0
	case "$pl" in
	passwd | password | admin | 123456 | 12345678 | 123456789 | 111111 | qwerty | debian | ubuntu | toor | root | password123 | admin123 | passwd123 | 00000000)
		return 0
		;;
	esac
	return 1
}

cred_username_ok() {
	local u="$1"
	if [[ ! "$u" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
		prompt -e "用户名必须小写字母开头，仅字母/数字/_/-，最长 32"
		return 1
	fi
	if cred_username_is_weak "$u"; then
		prompt -e "用户名「$u」太常见，爆破字典里有。请换一个（不要用 admin/user/test/debian）"
		return 1
	fi
	if [ "$u" = "root" ]; then
		prompt -e "不要用 root 当业务账号"
		return 1
	fi
	return 0
}

cred_set_user_password() {
	local user="$1" pass="$2"
	if ! echo "${user}:${pass}" | chpasswd; then
		prompt -e "chpasswd 失败，密码未写入"
		return 1
	fi
	prompt -s "已更新用户 $user 的登录密码"
}

cred_rand_from() {
	local n="$1" alphabet="$2" out="" rnd idx alen
	alen=${#alphabet}
	[ "$alen" -gt 0 ] && [ "$n" -gt 0 ] || return 1
	while [ ${#out} -lt "$n" ]; do
		rnd=$(od -An -N2 -tu2 /dev/urandom | tr -d '[:space:]')
		idx=$((rnd % alen))
		out+="${alphabet:$idx:1}"
	done
	printf '%s' "$out"
}

cred_generate_username() {
	local u i=0
	local alph='abcdefghijklmnopqrstuvwxyz0123456789'
	while [ "$i" -lt 40 ]; do
		u="s$(cred_rand_from 7 "$alph")"
		if [[ "$u" =~ ^[a-z][a-z0-9_-]{0,31}$ ]] && ! cred_username_is_weak "$u"; then
			printf '%s' "$u"
			return 0
		fi
		i=$((i + 1))
	done
	return 1
}

cred_generate_password() {
	local alph='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#%+=_'
	cred_rand_from 20 "$alph"
}

cred_save_file() {
	local f="$1" name="$2" pass="$3"
	local dir
	dir=$(dirname "$f")
	mkdir -p "$dir"
	umask 077
	cat >"$f" <<EOF
# Debian_Server_Init 自动生成的登录账号。勿提交 git。
# $(date -Iseconds 2>/dev/null || date)
SET_USER_NAME=$(printf '%q' "$name")
SET_USER_PASSWD=$(printf '%q' "$pass")
EOF
	chmod 600 "$f"
}

cred_apply_identity() {
	local old_name="${1:-}"
	if declare -F config_resolve_identity >/dev/null; then
		config_resolve_identity
	else
		CURRENT_USER="$SET_USER_NAME"
		HOME_INDEX="/home/$SET_USER_NAME"
	fi
	if [ -n "$old_name" ] && [ "$old_name" != "$SET_USER_NAME" ] && deploy_is_job_done "2/setup.sh"; then
		prompt -w "用户名已改，检查点二将重新执行以便创建新用户。"
		deploy_unmark_job "2/setup.sh"
	fi
	if id -u "$SET_USER_NAME" >/dev/null 2>&1; then
		cred_set_user_password "$SET_USER_NAME" "$SET_USER_PASSWD"
	fi
}

cred_print_login() {
	local name="$1" pass="$2" file="$3"
	echo
	echo -e "\e[1;31m==================== 请立刻抄下登录信息 ====================\e[0m"
	echo -e "\e[1;33m  用户名: ${name}\e[0m"
	echo -e "\e[1;33m  密  码: ${pass}\e[0m"
	echo -e "\e[1;32m  已写入: ${file} （权限 600，不要提交仓库）\e[0m"
	echo -e "\e[1;31m===========================================================\e[0m"
	echo
}

cred_prompt_manual() {
	local new_name new_pass new_pass2
	while true; do
		echo -n "新用户名: "
		read -r new_name
		if cred_username_ok "$new_name"; then
			break
		fi
	done
	while true; do
		echo -n "新密码（输入不可见，至少 8 位）: "
		read -r -s new_pass
		echo
		if cred_password_is_weak "$new_pass" "$new_name"; then
			prompt -e "密码太弱：至少 8 位，不能等于用户名，不能是 passwd/123456 等常见口令"
			continue
		fi
		echo -n "再输入一遍密码: "
		read -r -s new_pass2
		echo
		if [ "$new_pass" != "$new_pass2" ]; then
			prompt -e "两次密码不一致"
			continue
		fi
		break
	done
	SET_USER_NAME="$new_name"
	SET_USER_PASSWD="$new_pass"
}

cred_generate_pair() {
	SET_USER_NAME=$(cred_generate_username) || return 1
	SET_USER_PASSWD=$(cred_generate_password) || return 1
	if cred_username_is_weak "$SET_USER_NAME" || cred_password_is_weak "$SET_USER_PASSWD" "$SET_USER_NAME"; then
		return 1
	fi
	return 0
}

# 设置 CRED_MODE=auto|manual
cred_choose_mode() {
	CRED_MODE=auto
	if [ "${SET_CREDENTIALS_MANUAL:-0}" -eq 1 ]; then
		CRED_MODE=manual
		return 0
	fi
	if [ "${SET_CREDENTIALS_AUTO:-0}" -eq 1 ]; then
		CRED_MODE=auto
		return 0
	fi
	if ! deploy_tty_ok; then
		prompt -w "无终端：自动生成登录账号（不能交互选择）。"
		CRED_MODE=auto
		return 0
	fi
	echo
	prompt -w "登录账号不能用 admin/passwd（公网会被爆破）。请选择："
	echo "  1) 自动生成用户名和强密码（推荐）"
	echo "  2) 自己输入用户名和密码"
	local ans
	while true; do
		echo -n "请选择 [1/2]，直接回车 = 1: "
		read -r ans || ans=1
		ans=$(printf '%s' "${ans:-1}" | tr -d '[:space:]')
		case "$ans" in
		1)
			CRED_MODE=auto
			return 0
			;;
		2)
			CRED_MODE=manual
			return 0
			;;
		*)
			prompt -e "请输入 1 或 2"
			;;
		esac
	done
}

# 弱则询问自动生成或手输；已自定义 / 已有凭据文件则直接用。
force_change_default_credentials() {
	if [ "${SET_USER:-0}" -ne 1 ]; then
		prompt -w "SET_USER=0：以 root 继续。公网请先改掉 root 密码，并考虑禁止 SSH 密码登录。"
		return 0
	fi

	local cred_file old_name
	cred_file=$(cred_file_path)
	old_name="$SET_USER_NAME"

	if ! cred_username_is_weak "$SET_USER_NAME" && ! cred_password_is_weak "$SET_USER_PASSWD" "$SET_USER_NAME"; then
		prompt -s "账号已自定义：$SET_USER_NAME"
		return 0
	fi

	if [ -f "$cred_file" ]; then
		# shellcheck disable=SC1090
		source "$cred_file"
		if ! cred_username_is_weak "$SET_USER_NAME" && ! cred_password_is_weak "$SET_USER_PASSWD" "$SET_USER_NAME"; then
			prompt -s "已读取生成的账号文件: $cred_file （用户 $SET_USER_NAME）"
			cred_apply_identity "$old_name"
			return 0
		fi
	fi

	cred_choose_mode
	if [ "$CRED_MODE" = manual ]; then
		if ! deploy_tty_ok; then
			prompt -e "自己输入账号需要终端。请改跑 bash gen_credentials.sh --manual，或去掉 SET_CREDENTIALS_MANUAL 以自动生成。"
			exit 1
		fi
		cred_prompt_manual
	else
		cred_generate_pair || {
			prompt -e "自动生成失败，请重跑或改选手动输入"
			exit 1
		}
	fi

	cred_save_file "$cred_file" "$SET_USER_NAME" "$SET_USER_PASSWD"
	if [ "$(id -u)" -eq 0 ]; then
		cred_save_file "/root/.debian_server_init_login" "$SET_USER_NAME" "$SET_USER_PASSWD"
	fi
	cred_print_login "$SET_USER_NAME" "$SET_USER_PASSWD" "$cred_file"
	if [ "$(id -u)" -eq 0 ]; then
		prompt -m "另外备份: /root/.debian_server_init_login"
	fi
	if [ "${SET_ENABLE_SSH:-0}" -eq 1 ]; then
		prompt -w "即将启用 SSH。上面这组账号请存好，丢了只能上云控制台改。"
	fi
	if deploy_tty_ok; then
		echo -e "\e[1;33m已经抄下来了？按回车继续部署。\e[0m"
		read -r _
	else
		prompt -w "无终端：账号已生成并写入文件。请立刻打开 $cred_file 抄下来。"
	fi

	cred_apply_identity "$old_name"
	prompt -s "已采用用户 $SET_USER_NAME"
}

deploy_is_resume_skip_confirm() {
	[ "${SET_DEPLOY_RESUME:-1}" -eq 1 ] && deploy_has_completed_jobs && [ "${SET_DEPLOY_SKIP_CONFIRM:-1}" -eq 1 ]
}

# 首次必须在终端输入 y；直接回车 = 取消。仅续跑可跳过。
deploy_confirm_start() {
	if deploy_is_resume_skip_confirm; then
		deploy_print_completed_jobs
		prompt -m "续跑：跳过「是否开始部署」确认"
		return 0
	fi
	if ! deploy_tty_ok; then
		prompt -e "首次部署必须在真实终端里确认（输入 y）。不要用管道或没分配 TTY 的 ssh 直接跑。"
		prompt -w "Server：也可以先 bash gen_credentials.sh，再在终端里跑部署脚本。"
		exit 1
	fi
	comfirm "${1:-$'\e[1;31m输入 y 开始部署，直接回车取消 [y/N]\e[0m'}"
	local choice=$?
	if [ "$choice" -eq 1 ]; then
		prompt -m "开始部署……"
		return 0
	fi
	prompt -w "已取消。没准备好就先看 README / Config.sh。"
	exit 0
}

# 直接跑部署脚本时的警告；确认之后才会自动生成账号。
deploy_print_preflight() {
	local cred_file
	cred_file=$(cred_file_path)
	echo
	prompt -e "==================== 部署前确认（Server） ===================="
	prompt -w "这是 Debian 13 Server 一键部署：会改 APT、建用户、装软件，默认还启用 SSH。"
	prompt -k "当前身份：" "$(whoami) uid=${UID}"
	if [ "$UID" -ne 0 ]; then
		prompt -e "必须用 root 跑（不要只 sudo）。0_start 会拦，这里再提醒一次。"
	fi
	if [ "${SET_USER:-0}" -eq 1 ]; then
		if [ -f "$cred_file" ]; then
			prompt -s "已有账号文件：$cred_file （不会使用默认 admin/passwd）"
		elif ! cred_username_is_weak "$SET_USER_NAME" && ! cred_password_is_weak "$SET_USER_PASSWD" "$SET_USER_NAME"; then
			prompt -s "Config/环境变量已是自定义账号：$SET_USER_NAME"
		else
			prompt -e "占位账号 admin/passwd 不能上公网（会被爆破，云厂商可能直接关机）。"
			prompt -w "确认开始后将询问：1) 自动生成  2) 自己输入。不要用 admin/passwd。"
			prompt -w "也可先： bash gen_credentials.sh   或传入足够强的 SET_USER_NAME / SET_USER_PASSWD"
		fi
	else
		prompt -w "SET_USER=0：将以 root 继续。公网请先改掉 root 密码。"
	fi
	if [ "${SET_ENABLE_SSH:-0}" -eq 1 ]; then
		prompt -w "Config：SET_ENABLE_SSH=1，将启用 SSH 开机自启。"
	fi
	if [ "${SET_SUDOER_NOPASSWD:-0}" -eq 1 ]; then
		prompt -w "Config：SET_SUDOER_NOPASSWD=1，将设置 sudo 免密。"
	fi
	prompt -e "=============================================================="
	echo
}

deploy_has_completed_jobs() {
	[ -f "$DEPLOY_STATE_FILE" ] && [ -s "$DEPLOY_STATE_FILE" ]
}

deploy_print_completed_jobs() {
	if deploy_has_completed_jobs; then
		prompt -m "以下步骤已完成，续跑时将自动跳过："
		while IFS= read -r _line; do
			[ -n "$_line" ] && prompt -k "  ✓" "$_line"
		done <"$DEPLOY_STATE_FILE"
	fi
}

do_job() {
	local script="$1"
	local log_file="$2"
	local job_key
	local _job_rc=0

	job_key=$(deploy_job_key "$script")

	if [ "${SET_DEPLOY_RESUME:-1}" -eq 1 ] && deploy_is_job_done "$job_key"; then
		prompt -m "跳过已完成步骤: $job_key"
		log_message "日志：已跳过（续跑）- $job_key" "$log_file"
		return 0
	fi

	log_message "日志：任务开始 - $job_key" "$log_file"

	# 当前 shell + 真实 TTY 中 source，不经过管道/tee。
	source "$script"
	_job_rc=$?
	# 真正失败应走 quitThis（exit 1）。这里不把「脚本最后一条命令」的非零当成整步失败。
	if [ "$_job_rc" -ne 0 ]; then
		log_message "日志：任务结束（末条命令退出码 $_job_rc）- $job_key" "$log_file"
	fi

	if [ "${SET_DEPLOY_RESUME:-1}" -eq 1 ]; then
		deploy_mark_job_done "$job_key"
	fi
	log_message "日志：任务结束 - $job_key" "$log_file"
}

# 将"【$xxx】"复制为真实变量xxx的值
replace_placeholders_with_values() {
	local src_file="$1"
	local dest_file="$src_file"
	# 如果文件是 .src 结尾，生成去掉 .src 的文件
	if [[ "$src_file" == *.src ]]; then
		dest_file="${src_file%.src}"
	fi
	# 确认源文件是否存在
	if [[ ! -f "$src_file" ]]; then
		echo "文件不存在: $src_file"
		return 1
	fi
	# 复制文件内容到目标文件，如果需要新建
	cp "$src_file" "$dest_file"
	# 匹配占位符格式【$varName】，使用 sed 替换变量
	grep -oP '【\$\w+】' "$dest_file" | while read -r placeholder; do
		varName=$(echo "$placeholder" | sed -E 's/【\$(\w+)】/\1/')
		varValue=${!varName}
		if [[ -n "$varValue" ]]; then
			sed -i "s|${placeholder}|${varValue}|g" "$dest_file"
		else
			echo "警告: 变量 $varName 未设置，跳过替换 ${placeholder}"
		fi
	done
	echo "完成: 生成的文件为 $dest_file"
}

replace_placeholders_with_values_support_multiline() {
	local src_file="$1"
	local dest_file="$src_file"

	# 如果文件是 .src 结尾，生成去掉 .src 的文件
	if [[ "$src_file" == *.src ]]; then
		dest_file="${src_file%.src}"
	fi

	# 确认源文件是否存在
	if [[ ! -f "$src_file" ]]; then
		echo "文件不存在: $src_file"
		return 1
	fi

	# 复制文件内容到目标文件，如果需要新建
	cp "$src_file" "$dest_file"

	# 匹配占位符格式【$varName】，使用 sed 替换变量
	grep -oP '【\$\w+】' "$dest_file" | while read -r placeholder; do
		# 提取变量名
		varName=$(echo "$placeholder" | sed -E 's/【\$(\w+)】/\1/')

		# 获取变量值
		varValue=${!varName}

		if [[ -n "$varValue" ]]; then
			# 处理变量值中的换行符，替换为特殊字符（如 \n），避免被 sed 破坏
			varValue=$(echo "$varValue" | sed ':a;N;$!ba;s/\n/\\n/g')

			# 替换文件中的占位符为变量值
			sed -i "s|${placeholder}|${varValue}|g" "$dest_file"
		else
			echo "警告: 变量 $varName 未设置，跳过替换 ${placeholder}"
		fi
	done

	# 恢复特殊字符中的换行符
	sed -i 's/\\n/\n/g' "$dest_file"

	echo "完成: 生成的文件为 $dest_file"
}

### archive
# 新建文件夹 $1
addFolder251010() {
	if [ $# -ne 1 ]; then
		prompt -e "addFolder () 只能有一个参数"
		quitThis
	fi
	if ! [ -d $1 ]; then
		prompt -x "新建文件夹$1 "
		mkdir -p $1
	fi
	if ! [ -d $1 ]; then
		prompt -x "(sudo)新建文件夹$1 "
		sudo mkdir -p $1
	fi
}

# 替换用户名为使用已定义的 $CURRENT_USER replace_username "需要修改的文件"
replace_username() {
	local file="$1"
	# 检查文件是否有效
	if [[ -z "$file" || ! -f "$file" ]]; then
		prompt -e "Error: Please provide a valid file."
		quitThis
	fi
	# 使用已定义的 $CURRENT_USER
	local username="$CURRENT_USER"
	# 去掉 .src 扩展名生成新文件名
	local new_file="${file%.src}"
	# 复制文件并替换内容
	cp "$file" "$new_file"
	sed -i "s/changeUserName/$username/g" "$new_file"
	echo "Replaced 'changeUserName' with '$username' in $new_file."
}

backupFile_1.0() {
	if [ -f "$1" ]; then
		# 如果有bak备份文件 ，生成newbak
		if [ -f "$1.bak" ]; then
			# bak文件存在
			prompt -x "(sudo)正在备份 $1 文件到 $1.newbak (覆盖) "
			sudo cp $1 $1.newbak
		else
			# 没有bak文件，创建备份
			prompt -x "(sudo)正在备份 $1 文件到 $1.bak"
			sudo cp $1 $1.bak
		fi
	else
		# 如果不存在要备份的文件,不执行
		prompt -e "没有$1文件，不做备份"
	fi
}

doAsRoot2.0() {
	if [ "$ROOT_PASSWD" == "" ] && [ "$IS_SUDOER" -ne 1 ]; then
		prompt -w "未在脚本里定义root用户密码，请输入root用户密码: "
		read -r input
		ROOT_PASSWD=$input
	fi
	# 检查密码
	checkRootPasswd
	FIRST_DO_AS_ROOT=0
	if [ "$(whoami)" != "root" ]; then
		echo "Not root, switching to root user..."
		echo "$ROOT_PASSWD" | su -c "$1" -l
	else
		eval "$1"
	fi
}

doAsRoot1.0() {
	# 第一次运行需要询问root密码
	if [ "$FIRST_DO_AS_ROOT" -eq 1 ]; then
		if [ "$ROOT_PASSWD" == "" ] && [ "$IS_SUDOER" -ne 1 ]; then
			prompt -w "未在脚本里定义root用户密码，请输入root用户密码: "
			read -r input
			ROOT_PASSWD=$input
		fi
		# 检查密码
		checkRootPasswd
		FIRST_DO_AS_ROOT=0
	fi
	# 下面不能有缩进！
	su - root <<! >/dev/null 2>&1
$ROOT_PASSWD
echo " Exec $1 as root"
$1
!
}

# For debug code hightlight (需要代码高亮的时候取消注释,使用的时候注释掉)
# !>/dev/null 2>&1

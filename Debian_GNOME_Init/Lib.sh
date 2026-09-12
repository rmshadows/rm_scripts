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
	exit 1
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

# 检查点一改完源后的保留清单（modernize / 写入的官方源）。之后多出来的当第三方。
deploy_apt_keep_file() {
	printf '%s' "${DEPLOY_APT_KEEP_FILE:-${DEPLOY_SCRIPT_ROOT:-.}/.deploy_apt_keep}"
}

deploy_apt_snapshot_keep() {
	local keep f base
	keep=$(deploy_apt_keep_file)
	: >"$keep"
	for f in /etc/apt/sources.list.d/*; do
		[ -f "$f" ] || continue
		base=$(basename "$f")
		printf '%s\n' "$base" >>"$keep"
		prompt -k "保留源" "$base"
	done
	prompt -s "已记录检查点一之后的 APT 源: $keep"
}

deploy_apt_disable_third_party() {
	local keep f base
	keep=$(deploy_apt_keep_file)
	if [ ! -s "$keep" ]; then
		prompt -w "没有检查点一的源清单（$keep），不挪 sources.list.d，以免误删主库。"
		return 0
	fi
	addFolder /etc/apt/sources.list.d/backup
	for f in /etc/apt/sources.list.d/*; do
		[ -e "$f" ] || continue
		[ -d "$f" ] && continue
		base=$(basename "$f")
		if grep -qxF "$base" "$keep"; then
			continue
		fi
		prompt -x "挪走检查点一之后新增的源: $base"
		sudo mv "$f" /etc/apt/sources.list.d/backup/
	done
}

# 交互式安装（wireshark / 显示管理器 / apt-listchanges 等）必须连真实 TTY。
# 管道、tee、未 flush 的 script 都会让界面画不出来、按键进不去。
deploy_tty_ok() {
	[ -t 0 ] && [ -t 1 ] && [ -t 2 ]
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
		prompt -e "首次部署必须在真实终端里确认（输入 y）。请在 GNOME 终端直接运行："
		prompt -w "bash Debian_13_GNOME_Setup.sh"
		exit 1
	fi
	comfirm "${1:-$'\e[1;31m输入 y 开始部署，直接回车取消 [y/N]\e[0m'}"
	local choice=$?
	if [ "$choice" -eq 1 ]; then
		prompt -m "开始部署……"
		return 0
	fi
	prompt -w "已取消。没看过 Config.sh 就先看再跑。"
	exit 0
}

deploy_print_preflight() {
	echo
	prompt -e "==================== 部署前确认（GNOME） ===================="
	prompt -w "这是 Debian 13 GNOME 一键部署，会改 APT、sudo、zsh、输入法、扩展等。"
	prompt -e "请用普通用户跑，不要 root。当前用户：$CURRENT_USER"
	prompt -k "桌面会话：" "${DESKTOP_SESSION:-未知}"
	prompt -k "是否 sudo 组成员：" "${is_sudoer:--}"
	prompt -k "当前 sudo 是否免密：" "${is_sudo_nopasswd:--}"
	if [ "${SET_SUDOER_NOPASSWD:-0}" -eq 1 ]; then
		prompt -w "Config：SET_SUDOER_NOPASSWD=1，将把当前用户设为 sudo 免密。"
	fi
	if [ "${SET_BASH_TO_ZSH:-0}" -eq 1 ]; then
		prompt -w "Config：会把 Bash 换成 Zsh（含 root）。"
	fi
	if dpkg-query -W -f='${Status}' raspi-firmware 2>/dev/null | grep -q "install ok installed"; then
		prompt -e "检测到 raspi-firmware。Debian 12+ 系统升级经常被它搞挂。"
		prompt -w "建议先另开终端执行： sudo apt purge raspi-firmware"
	fi
	if [ "${IS_SUDOER:-0}" -ne 1 ] && [ -z "${ROOT_PASSWD:-}" ]; then
		prompt -w "你不在 sudo 组，且未设置 ROOT_PASSWD。确认后会要 root 密码。"
	fi
	prompt -w "直接跑本脚本可以，但请确认已经看过 Config.sh。"
	prompt -e "=============================================================="
	echo
}

# 确认前做能做的检查：TTY、root 密码（若需要）
deploy_gnome_prepare() {
	if ! deploy_tty_ok && ! deploy_is_resume_skip_confirm; then
		prompt -e "没有交互终端。debconf / wireshark / 显示管理器会卡住。"
		prompt -w "请在 GNOME 终端运行： bash Debian_13_GNOME_Setup.sh"
		exit 1
	fi
	if [ "${IS_SUDOER:-0}" -ne 1 ] && [ -z "${ROOT_PASSWD:-}" ]; then
		if ! deploy_tty_ok; then
			prompt -e "需要 root 密码，但当前无终端。"
			exit 1
		fi
		prompt -w "未在 GlobalVariables/环境变量里设置 ROOT_PASSWD，请输入 root 密码: "
		read -r ROOT_PASSWD
		checkRootPasswd
		prompt -s "root 密码可用"
	fi
}

deploy_prepare_interactive() {
	if ! deploy_tty_ok; then
		prompt -e "stdin/stdout/stderr 不是终端。debconf / pager / ncurses 无法显示，也无法接收按键。"
		prompt -w "请直接在终端运行：bash Debian_13_GNOME_Setup.sh（不要再套一层管道或无 -t 的 ssh）"
		return 1
	fi
	# 有 TTY 时禁止 noninteractive，否则 wireshark、gdm/sddm 选择等会静默卡住或乱选
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
	# 安装/升级会弹出 debconf（wireshark dumpcap、显示管理器、键盘布局等），必须在 TTY 上跑
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
	# wireshark、显示管理器、apt-listchanges 等都靠 debconf/ncurses，必须 isatty。
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

#!/bin/bash
# https://github.com/rmshadows/rm_scripts

export DEPLOY_SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DEPLOY_SCRIPT_ROOT" || exit 1

:<<!说明
Version：0.1.9
!说明


#### 初始化脚本
# 加载全局变量
source "GlobalVariables.sh"
# 加载全局函数
source "Lib.sh"
# 加载配置(在全局变量之后)
source "Config.sh"

# 各检查点会 cd 到 1/ 2/ …，日志路径必须是绝对路径，否则会写成 1/setup.log、2/setup.log
if [[ "$ELOG_FILE" != /* ]]; then
	ELOG_FILE="$DEPLOY_SCRIPT_ROOT/$ELOG_FILE"
fi

# 默认直连真实终端。全文录像会套一层 PTY，debconf/ncurses 可能画不出或按键延迟。
if [ "${SET_DEPLOY_FULL_LOG:-0}" -eq 1 ] && [ -z "${DEPLOY_UNDER_SCRIPT:-}" ] && deploy_tty_ok && command -v script >/dev/null 2>&1; then
	export DEPLOY_UNDER_SCRIPT=1
	exec script -q -e -a -f -c "bash \"$DEPLOY_SCRIPT_ROOT/Debian_13_Server_Setup.sh\"" "$DEPLOY_SCRIPT_ROOT/${ELOG_FILE:-setup.log}"
fi
deploy_prepare_interactive || true

if [ "${SET_DEPLOY_RESET:-0}" -eq 1 ]; then
	deploy_reset_state
	prompt -m "已清除部署进度，将从头运行"
fi

# 脚本开始
source "0/0_start.sh"

# 预执行
source "0/init.sh"

#### 正文开始


cd 1
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 2
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 3
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 4
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 5
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 6
do_job "setup.sh" "$ELOG_FILE"
cd ..

cd 0
do_job "install_later.sh" "$ELOG_FILE"
do_job "the_end.sh" "$ELOG_FILE"
cd ..

#### 脚本结束
source "0/1_end.sh"

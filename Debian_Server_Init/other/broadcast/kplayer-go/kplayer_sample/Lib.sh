#!/bin/bash
: <<!说明
这里是函数库
依赖 GlobalVariables.sh
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
  "-k" | "--kv")                                       # 三个参数
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

# 执行apt命令 注意，检查点一后才能使用这个方法
doApt() {
  prompt -x "doApt: $@"
  # 如果是第一次运行apt
  if [ "$FIRST_DO_APT" -eq 1 ]; then
    prompt -w "如果APT显示被占用，『对此的通常建议是等待』。如果你没有耐心，请尝试根据报错决定是否运行下列所示的命令(删锁、dpkg重配置)，注意：后者是极不建议的！"
    prompt -e "sudo rm /var/lib/dpkg/lock-frontend && sudo rm /var/lib/dpkg/lock && sudo dpkg --configure -a"
    FIRST_DO_APT=0
    sleep 5
  fi
  if [ "$1" = "install" ] || [ "$1" = "remove" ] || [ "$1" = "dist-upgrade" ] || [ "$1" = "upgrade" ]; then
    if [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 0 ]; then
      sudo apt $@
    elif [ "$SET_APT_RUN_WITHOUT_ASKING" -eq 1 ]; then
      sudo apt $@ -y
    fi
  else
    sudo apt $@
  fi
}

# 新建文件夹 $1
addFolder() {
  if [ $# -ne 1 ]; then
    prompt -e "addFolder () 只能有一个参数"
    quitThis
  fi
  if ! [ -d $1 ]; then
    prompt -x "新建文件夹$1 "
    mkdir $1
  fi
  if ! [ -d $1 ]; then
    prompt -x "(sudo)新建文件夹$1 "
    sudo mkdir $1
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
do_job() {
  local script="$1"
  local log_file="$2"

  # 获取当前工作目录
  local current_dir=$(pwd)

  # 记录任务开始的日志，包含当前目录和脚本名
  log_message "日志：任务开始 - $current_dir/$(basename "$script")" "$log_file"

  {
    # 通过进程替换处理标准错误，逐行读取并加上 [stderr]
    source "$script" 2> >(while IFS= read -r line; do
      echo -e "\033[1;31;47m [stderr] \033[0m $line" # 红字白底
    done) |
      while IFS= read -r line; do
        echo "[stdout] $line" # 标准输出标记为 [stdout]
      done
  } | tee -a "$log_file" # 将输出追加到日志文件

  # 记录任务结束的日志，包含当前目录和脚本名
  log_message "日志：任务结束 - $current_dir/$(basename "$script")" "$log_file"
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

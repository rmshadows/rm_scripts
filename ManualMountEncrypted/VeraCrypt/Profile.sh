#!/bin/bash
## 控制台颜色输出
# 红色：警告、重点
# 黄色：警告、一般打印
# 绿色：执行日志
# 蓝色、白色：常规信息
# 颜色colors
CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # warning color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"  
# echo like ...  with  flag type  and display message  colors
# -s 绿
# -e 红
# -w 黄
# -i 蓝
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;          # print success message
    "-x"|"--exec")
      echo -e "Exec Log：${b_CGSC}${@/-x/}${CDEF}";;          # print exec message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    "-m"|"--msg")
      echo -e "Msg：${b_CCIN}${@/-m/}${CDEF}";;          # print iinfo message
    "-k"|"--kv")  # 三个参数
      echo -e "${b_CCIN} ${2} ${b_CWAR} ${3} ${CDEF}";;          # print k:v message
    *)
    echo -e "$@"
    ;;
  esac
}

testPrintln(){
    prompt -s "成功信息（绿色）"
    prompt -x "执行日志（绿色）"
    prompt -e "错误信息（红色）"
    prompt -w "警告信息（黄色）"
    prompt -i "普通信息（蓝色）"
    prompt -m "普通消息（蓝色）"
    prompt -k "一个参数（蓝色）" "两个参数（黄色）"
}


civiccccc (){
  echo -e "\e[1;31m
_________  .___ ____   ____.___ _________  _________  _________  _________  _________  
\_   ___ \ |   |\   \ /   /|   |\_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ 
/    \  \/ |   | \   Y   / |   |/    \  \/ /    \  \/ /    \  \/ /    \  \/ /    \  \/ 
\     \____|   |  \     /  |   |\     \____\     \____\     \____\     \____\     \____
 \______  /|___|   \___/   |___| \______  / \______  / \______  / \______  / \______  /
        \/                              \/         \/         \/         \/         \/ 
\e[1;32m"
}


## 询问函数 Yes:1 No:2 ???:5
:<<'!询问函数'
函数调用请使用：
comfirmn "\e[1;33m? [y/N]\e[0m"
comfirmy "\e[1;33m? [Y/n]\e[0m"
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
# 交互读输入：优先 /dev/tty，避免 shc 二进制下 stdin 异常
_read_user() {
  if [ -r /dev/tty ]; then
    read -r "$@" </dev/tty
  else
    read -r "$@"
  fi
}

comfirmy () {
  flag=true
  ask=$1
  while $flag
  do
    echo -e "$ask"
    _read_user input
    if [ -z "${input}" ];then
      # 默认选择Y
      input='y'
    fi
    case $input in [yY][eE][sS]|[yY])
      return 1
      flag=false
    ;;
    [nN][oO]|[nN])
      return 2
      flag=false
    ;;
    *)
      prompt -w "Invalid option..."
    ;;
    esac
  done
}

comfirmn () {
  flag=true
  ask=$1
  while $flag
  do
    echo -e "$ask"
    _read_user input
    if [ -z "${input}" ];then
      # 默认选择N
      input='n'
    fi
    case $input in [yY][eE][sS]|[yY])
      return 1
      flag=false
    ;;
    [nN][oO]|[nN])
      return 2
      flag=false
    ;;
    *)
      prompt -w "Invalid option..."
    ;;
    esac
  done
}


# testPrintln

# ---- /media/用户名 挂载命名（fixed | label | label-or-fixed）----
media_user_root() {
  printf '%s\n' "/media/${_MEDIA_USER:-${SUDO_USER:-${USER:-$(id -un)}}}"
}

sanitize_mount_name() {
  local raw="$1"
  raw="$(printf '%s' "$raw" | tr -d '\0' | sed 's#[/\\]#_#g')"
  raw="$(printf '%s' "$raw" | sed 's/^[[:space:].]*//;s/[[:space:].]*$//')"
  if [ -z "$raw" ] || [ "$raw" = "." ] || [ "$raw" = ".." ]; then
    return 1
  fi
  printf '%s\n' "$raw"
}

# 判断「路径本身」是不是挂载点。
# 勿用 findmnt --target：对已存在的普通目录会命中父挂载 /，造成假阳性。
is_mountpoint() {
  local p="$1"
  [ -n "$p" ] || return 1
  findmnt -n --mountpoint "$p" >/dev/null 2>&1
}

pick_unique_media_path() {
  local base="$1" cand="$1" n=2
  while true; do
    if is_mountpoint "$cand"; then
      cand="${base}_${n}"
      n=$((n + 1))
      continue
    fi
    if [ -d "$cand" ] && [ -n "$(sudo ls -A "$cand" 2>/dev/null)" ]; then
      cand="${base}_${n}"
      n=$((n + 1))
      continue
    fi
    printf '%s\n' "$cand"
    return 0
  done
}

# $1=卷标（可空）。设置全局 readMount。
resolve_media_read_mount() {
  local label="${1:-}" mode="${mountNameMode:-label-or-fixed}"
  local fixed="${mountName:-mounted}" name root
  root="$(media_user_root)"
  case "$mode" in
    fixed)
      name="$fixed"
      prompt -k "挂载命名" "固定名 → $name"
      ;;
    label)
      if ! name="$(sanitize_mount_name "$label")"; then
        prompt -e "卷没有可用卷标，且 mountNameMode=label"
        return 1
      fi
      prompt -k "挂载命名" "卷标 → $name"
      prompt -k "原始卷标" "$label"
      ;;
    label-or-fixed|*)
      if name="$(sanitize_mount_name "$label")"; then
        prompt -k "挂载命名" "卷标 → $name"
        prompt -k "原始卷标" "$label"
      else
        name="$fixed"
        prompt -k "挂载命名" "无卷标，回退固定名 → $name"
      fi
      ;;
  esac
  readMount="$(pick_unique_media_path "$root/$name")"
  if [ "$readMount" != "$root/$name" ]; then
    prompt -w "目标目录被占用，改用: $readMount"
  fi
  prompt -k "访问目录" "$readMount"
  return 0
}

save_last_read_mount() {
  local state_dir="${1:-.}"
  mkdir -p "$state_dir" 2>/dev/null || true
  printf '%s\n' "$readMount" >"${state_dir}/.last-readmount"
}

load_last_read_mount() {
  local state_dir="${1:-.}" f="${state_dir}/.last-readmount" mp
  [ -f "$f" ] || return 1
  mp="$(tr -d '\r\n' <"$f")"
  [ -n "$mp" ] || return 1
  if is_mountpoint "$mp"; then
    readMount="$mp"
    return 0
  fi
  return 1
}

# 卸载成功后删掉 /media/... 下空挂载目录，避免下次 RyanWS_2、_3…
remove_empty_media_dir() {
  local mp="$1"
  case "$mp" in
    /media/*) ;;
    *) return 0 ;;
  esac
  is_mountpoint "$mp" && return 0
  [ -d "$mp" ] || return 0
  if [ -z "$(sudo ls -A "$mp" 2>/dev/null)" ]; then
    if sudo rmdir "$mp" 2>/dev/null; then
      prompt -i "已删除空挂载目录: $mp"
    fi
  fi
}

# 卸载失败时列出占用该挂载点的进程。
show_mount_holders() {
  local mp="$1" cwd out
  prompt -w "卸载失败，正在查看谁占用了: $mp"
  cwd="$(pwd -P 2>/dev/null || pwd)"
  case "$cwd" in
    "$mp"|"$mp"/*)
      prompt -e "当前终端的工作目录就在这里: $cwd"
      prompt -i "先 cd 到别的目录，再卸载。"
      ;;
  esac

  if ! command -v lsof >/dev/null 2>&1 && ! command -v fuser >/dev/null 2>&1; then
    prompt -w "没有 lsof/fuser，尝试安装…"
    sudo apt install -y lsof psmisc || true
  fi

  if command -v lsof >/dev/null 2>&1; then
    out="$(sudo lsof -nP +f -- "$mp" 2>/dev/null || true)"
    if [ -n "$out" ]; then
      echo "$out"
      prompt -i "关掉上面的程序，或离开该目录后再卸载。"
      return 0
    fi
  fi

  if command -v fuser >/dev/null 2>&1; then
    prompt -i "lsof 没有结果，再用 fuser："
    if sudo fuser -vm "$mp"; then
      prompt -i "关掉上面的程序，或离开该目录后再卸载。"
      return 0
    fi
  fi

  prompt -w "没有查到打开该目录的进程。若刚关了窗口，等一两秒再卸一次。"
  return 1
}

#!/usr/bin/env bash
# =============================================================================
# 本文件由 pack_shc.sh 自动生成，请勿手改长期维护。
# 内含：Profile + config（打包时快照）+ mountB 函数 + 统一入口
# =============================================================================
set -euo pipefail

resolve_runtime_dirs() {
  local exe
  if [[ -r /proc/self/exe ]]; then
    exe="$(readlink -f /proc/self/exe 2>/dev/null || true)"
  fi
  if [[ -n "${exe:-}" && -e "$exe" ]]; then
    PACK_BIN_DIR="$(cd "$(dirname "$exe")" && pwd)"
  else
    PACK_BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi
  STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ManualMountEncrypted-BitLocker"
  mkdir -p "$STATE_DIR"
  # mountB / detect 里用 SCRIPT_DIR 写 .last-readmount
  SCRIPT_DIR="$STATE_DIR"
}

resolve_runtime_dirs
DISLOCKER_BIN=""

# ---- Profile.sh ----
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
comfirmy () {
  flag=true
  ask=$1
  while $flag
  do
    echo -e "$ask"
    read -r input
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
    read -r input
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

pick_unique_media_path() {
  local base="$1" cand="$1" n=2
  while true; do
    if findmnt -n --target "$cand" >/dev/null 2>&1; then
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
  if findmnt -n --target "$mp" >/dev/null 2>&1; then
    readMount="$mp"
    return 0
  fi
  return 1
}

# 把 /media/用户名/ 下的挂载点目录改成用户所有，方便 Nautilus 显示。
own_media_mount_dir() {
  local dir="$1"
  local owner="${_MEDIA_USER:-${SUDO_USER:-${USER:-$(id -un)}}}"
  if [[ "$dir" != /media/"$owner"/* ]]; then
    return 0
  fi
  if [ ! -d "/media/$owner" ]; then
    sudo mkdir -p "/media/$owner" || return 1
    sudo chown "$owner:$owner" "/media/$owner" || return 1
  fi
  if [ -d "$dir" ]; then
    sudo chown "$owner:$owner" "$dir" 2>/dev/null || true
  fi
  return 0
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

# 确保挂载目录存在且为空（可读挂载点专用）。
prepare_empty_mount_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    prompt -x "mkdir $dir"
    sudo mkdir -p "$dir" || return 1
    own_media_mount_dir "$dir"
    return 0
  fi
  if [ -n "$(sudo ls -A "$dir" 2>/dev/null)" ]; then
    prompt -e "挂载点 $dir 非空。"
    sudo ls -la "$dir"
    comfirmn "\e[1;33m 是否清空 $dir ？此操作不可恢复 [y/N]\e[0m"
    choice=$?
    if [ "$choice" -eq 1 ]; then
      prompt -x "清空挂载点 $dir ..."
      sudo rm -rf "$dir" || return 1
      prompt -x "mkdir $dir"
      sudo mkdir -p "$dir" || return 1
      own_media_mount_dir "$dir"
    elif [ "$choice" -eq 2 ]; then
      prompt -w "已取消。"
      return 1
    else
      prompt -e "未知选项。"
      return 1
    fi
  else
    own_media_mount_dir "$dir"
  fi
  return 0
}

# 查找 BitLocker 可读挂载点（依赖 .last-readmount / 固定名）。
detect_existing_bitlocker_mount() {
  local fixed
  if load_last_read_mount "${SCRIPT_DIR:-.}" && findmnt -n --target "$readMount" >/dev/null 2>&1; then
    prompt -k "已挂载(记录)" "$readMount"
    return 0
  fi
  fixed="$(media_user_root)/${mountName:-bitlockermount}"
  if findmnt -n --target "$fixed" >/dev/null 2>&1; then
    readMount="$fixed"
    prompt -k "已挂载(固定名)" "$readMount"
    return 0
  fi
  return 1
}

# ---- config.sh（打包快照，改配置请改源码旁 config.sh 后重新打包）----
# BitLocker 挂载参数。mountB.sh、rmount.sh、urmount.sh 都会读取本文件。
#
# 银河麒麟系统关闭执行控制功能状态：
# sudo setstatus -f exectl off
# setstatus -p softmode
# 开机自动挂载需要修改 fstab（修改前记得备份）：
# <partition> /media/bitlocker fuse.dislocker user-password=<password>,nofail 0 0
# /media/bitlocker/dislocker-file /media/bitlockermount auto nofail 0 0
#
# 查看分区 PARTUUID：
#   lsblk -o NAME,PARTUUID,SIZE,FSTYPE,TYPE

# BitLocker 加密分区的 PARTUUID
puid="4463e4a8-296b-4db9-aa4d-7c83c762665e"
# /dev/sdb4: TYPE="BitLocker" PARTUUID="4463e4a8-296b-4db9-aa4d-7c83c762665e"

# dislocker 解密后的挂载点（中间层，一般不直接浏览）
dislockMount="/home/bitlocker"
# 可访问的挂载点。默认放在 /media/用户名/ 下，Nautilus 侧栏才容易出现。
_MEDIA_USER="${SUDO_USER:-${USER:-$(id -un)}}"
# fixed=固定名 | label=必须用卷标 | label-or-fixed=有卷标用卷标，否则回退
mountNameMode=label-or-fixed
# 固定名 / 无卷标时的回退名
mountName="bitlockermount"
# 实际路径由脚本在解密后写入 readMount；也可手动写死绝对路径覆盖：
# readMount="/media/${_MEDIA_USER}/bitlockermount"
readMount="/media/${_MEDIA_USER}/${mountName}"

# 解密方式  0:密码  1:恢复密钥
keyMode=0
# 没有密码就保持注释。写在这里会进入进程列表，交互输入更安全。
# keyPass=""

# 留空则使用系统 dislocker。系统自带版本有问题时再指定，例如：
# DISLOCKER_CUSTOM="./UOS-arm64/dislocker"
# DISLOCKER_CUSTOM="./Debian12-amd64/dislocker"
# DISLOCKER_CUSTOM="./KylinV10sp1-arm64/dislocker"
DISLOCKER_CUSTOM=""

# 相对路径的 DISLOCKER_CUSTOM 按二进制目录解析
if [ -n "${DISLOCKER_CUSTOM:-}" ] && [[ "$DISLOCKER_CUSTOM" != /* ]]; then
  DISLOCKER_CUSTOM="$PACK_BIN_DIR/$DISLOCKER_CUSTOM"
fi

# ---- mountB.sh 函数 ----
# 函数：检查单个挂载点是否挂载
check_mount_point() {
    local mount_point="$1"
    findmnt -n --target "$mount_point" >/dev/null 2>&1
}

# 函数：检查 BitLocker 磁盘是否挂载
check_bitlocker_mount() {
    if check_mount_point "$dislockMount" && check_mount_point "$readMount"; then
        return 0 # 两个挂载点都已挂载
    else
        return 1 # 至少一个挂载点未挂载
    fi
}

check_bitlocker_mount_adv() {
    # 0: both
    # 1: readMount
    # 2: dislockMount
    # 3: neither
    # 4: other
    if check_mount_point "$dislockMount" && check_mount_point "$readMount"; then
        return 0
    elif ! check_mount_point "$dislockMount" && check_mount_point "$readMount"; then
        return 1
    elif check_mount_point "$dislockMount" && ! check_mount_point "$readMount"; then
        return 2
    elif ! check_mount_point "$dislockMount" && ! check_mount_point "$readMount"; then
        return 3
    else
        return 4
    fi
}

umountBitlocker() {
    comfirmy "\e[1;33m BitLocker disk mounted at $readMount . Umount ? [Y/n]\e[0m"
    choice=$?
    usuccess=0
    if [ $choice == 1 ]; then
        if check_mount_point "$readMount"; then
            sudo umount "$readMount" || { usuccess=1; show_mount_holders "$readMount"; }
        fi
        sleep 1
        if check_mount_point "$dislockMount"; then
            sudo umount "$dislockMount" || { usuccess=1; show_mount_holders "$dislockMount"; }
        fi
    elif [ $choice == 2 ]; then
        prompt -i "Quit."
    else
        prompt -e "ERROR:未知返回值!"
        exit 5
    fi
    if [ "$usuccess" -eq 0 ]; then
        prompt -s "Disk unmounted successfully."
        rm -f "$SCRIPT_DIR/.last-readmount" 2>/dev/null || true
    else
        prompt -e "WARN: An error may occur during the umount process, check manual."
    fi
}

mountBitlockerDisk() {
    comfirmy "\e[1;33m BitLocker disk not mounted.Mount ? [Y/n]\e[0m"
    choice=$?
    if [ $choice == 1 ]; then
        # 获取用户名
        USERNAME="$USER"

        # 判断是否存在自定义 dislocker
        if [[ -x "$DISLOCKER_CUSTOM" ]]; then
            DISLOCKER_BIN="$DISLOCKER_CUSTOM"
            echo "[INFO] 使用指定的 dislocker: $DISLOCKER_BIN"
        elif command -v dislocker &>/dev/null; then
            DISLOCKER_BIN=$(command -v dislocker)
            echo "[INFO] 使用系统自带的 dislocker: $DISLOCKER_BIN"
        else
            echo "[ERROR] 未找到 dislocker 工具。"
            cmdToCheck="dislocker"
            if ! [ -x "$(command -v "$cmdToCheck")" ]; then
                # echo "Error: "$cmdToCheck" is not installed." >&2
                prompt -w "WARN: "$cmdToCheck" is not installed, try apt install."
                sudo apt install "$cmdToCheck" -y
            else
                # echo "Command found! : "$cmdToCheck"" >&1
                prompt -i "Command found! : "$cmdToCheck""
            fi
            # 再次检查
            if command -v dislocker &>/dev/null; then
                DISLOCKER_BIN=$(command -v dislocker)
                echo "[INFO] 安装成功，使用系统 dislocker: $DISLOCKER_BIN"
            else
                echo "[FATAL] 安装失败，仍未找到 dislocker。"
                exit 1
            fi
        fi

        ## 检查命令是否安装dislocker、fuse
        cmdToCheck="fusermount"
        if ! [ -x "$(command -v "$cmdToCheck")" ]; then
            # echo "Error: "$cmdToCheck" is not installed." >&2
            prompt -w "WARN: "$cmdToCheck" is not installed, try apt install."
            sudo apt install "$cmdToCheck" -y
        else
            # echo "Command found! : "$cmdToCheck"" >&1
            prompt -i "Command found! : "$cmdToCheck""
        fi

        pinfo=$(sudo blkid | grep "$puid")
        tempArgs=($pinfo)
        # /dev/sdb4:
        tempArgs=${tempArgs[0]}
        # /dev/sdb4
        pdev=${tempArgs::-1}
        # echo "Get Bitlocker Part: "$pdev"."
        prompt -i "Get Bitlocker Part: "$pdev"."
        prompt -s " => $pdev <="

        if [ ! -d "$dislockMount" ]; then
            prompt -x "mkdir $dislockMount"
            sudo mkdir -p "$dislockMount"
        else
            # 检查挂载点是否为空
            if [ "$(ls -A $dislockMount)" ]; then
                # echo "Mountpoint is not empty."
                prompt -e "Mountpoint $dislockMount is not empty."
                # 进一步处理，例如列出挂载点的内容
                ls -la $dislockMount
                comfirmn "\e[1;33m Whether to clear $dislockMount (CAN NOT BE UNDONE!) ? [y/N]\e[0m"
                choice=$?
                if [ $choice == 1 ]; then
                    prompt -x "Clear Mountpoint $dislockMount ..."
                    sudo rm -rf "$dislockMount"
                    prompt -x "mkdir $dislockMount"
                    sudo mkdir -p "$dislockMount"
                elif [ $choice == 2 ]; then
                    prompt -w "Quit."
                    exit 1
                else
                    prompt -e "Unknown option !"
                    exit 5
                fi
            fi
        fi

        ## 开始解密（可读挂载点等拿到卷标后再建）
        # sudo dislocker /dev/sdb4 -u -- /home/bitlocker
        # sudo umount /home/bitlocker
        # prompt -x "Try to mount (sudo dislocker "$pdev" -u -- "$dislockMount") ..."
        prompt -x "Try to mount (sudo "$DISLOCKER_BIN" "$pdev" -u -- "$dislockMount") ..."
        if [ "$keyMode" -eq 0 ]; then
            prompt -m "Decryption with password (-u)."
            # 判断是否提供了密码
            if [ -n "$keyPass" ]; then
                # 如果提供了密码，则使用提供的密码解锁
                echo "Using provided Bitlocker password..."
                # sudo dislocker "$pdev" -u"$keyPass" "$dislockMount"
                sudo "$DISLOCKER_BIN" "$pdev" -u"$keyPass" "$dislockMount"
            else
                # 如果未提供密码，则手动输入密码
                echo "Enter Bitlocker password when prompted..."
                # sudo dislocker "$pdev" -u -- "$dislockMount"
                sudo "$DISLOCKER_BIN" "$pdev" -u -- "$dislockMount"
            fi
        elif [ "$keyMode" -eq 1 ]; then
            prompt -m "Decryption with recovery key (-p)."
            # https://linux.cn/article-14008-1.html
            # 判断是否提供了密码
            if [ -n "$keyPass" ]; then
                # 如果使用的恢复密钥：
                echo "Using provided Bitlocker recovery key..."
                # sudo dislocker "$pdev" -p"$keyPass" "$dislockMount"
                sudo "$DISLOCKER_BIN" "$pdev" -p"$keyPass" "$dislockMount"
            else
                # 如果未提供密码，则手动输入密码
                echo "Enter Bitlocker password when prompted..."
                # sudo dislocker "$pdev" -p -- "$dislockMount"
                sudo "$DISLOCKER_BIN" "$pdev" -p -- "$dislockMount"
            fi
        else
            prompt -e "Error: Wrong decryption method selection (0~1, but $keyMode) ."
        fi

        if [ "$?" -ne 0 ]; then
            prompt -e "Error occurred while mounting."
            exit 1
        fi

        vol_label="$(sudo blkid -o value -s LABEL "$dislockMount/dislocker-file" 2>/dev/null || true)"
        prompt -k "检测到的卷标" "${vol_label:-（无）}"
        prompt -k "命名模式" "${mountNameMode:-label-or-fixed}"
        resolve_media_read_mount "$vol_label" || exit 1
        prepare_empty_mount_dir "$readMount" || exit 1

        # 下一个命令是把解密好的分区挂在到可读目录；loop 把文件当分区
        # ,uid=$(id -u ryan),gid=$(id -g ryan) 能解决回收站无法使用的问题
        sudo mount -o loop,uid=$(id -u $USERNAME),gid=$(id -g $USERNAME) "$dislockMount"/dislocker-file "$readMount"
        # sudo mount -o loop "$dislockMount"/dislocker-file "$readMount"
        save_last_read_mount "$SCRIPT_DIR"
        prompt -s "Mounted successfully: $readMount"
        # echo "Launched."
        # echo "Use below to unmount."
        prompt -i "Use below to unmount."
        echo ""
        prompt -s "sudo umount $readMount && sudo umount $dislockMount"
        # echo "sudo umount "$dislockMount""
        echo ""
    elif [ $choice == 2 ]; then
        prompt -i "Quit."
    else
        prompt -e "ERROR:未知返回值!"
        exit 5
    fi
}


# 覆盖：状态目录固定用 STATE_DIR
save_last_read_mount() {
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  printf '%s\n' "$readMount" >"${STATE_DIR}/.last-readmount"
}
load_last_read_mount() {
  local f="${STATE_DIR}/.last-readmount" mp
  [ -f "$f" ] || return 1
  mp="$(tr -d '\r\n' <"$f")"
  [ -n "$mp" ] || return 1
  if findmnt -n --target "$mp" >/dev/null 2>&1; then
    readMount="$mp"
    return 0
  fi
  return 1
}

packed_usage() {
  cat <<EOF
BitLocker 挂载工具（pack_shc 打包版）

用法:
  $(basename "$0")              交互：已挂载则询问卸载，否则询问挂载
  $(basename "$0") --mount|-m   直接挂载（同 rmount.sh）
  $(basename "$0") --umount|-u  直接卸载（同 urmount.sh）
  $(basename "$0") -h|--help    帮助
EOF
}

# 非交互：自动答「是」挂载确认；清目录类危险提问仍默认否
run_mount_direct() {
  comfirmy() { return 1; }
  comfirmn() { return 2; }
  mountBitlockerDisk
}

run_umount_direct() {
  local usuccess=0
  detect_existing_bitlocker_mount || true
  if check_mount_point "$readMount"; then
    sudo umount "$readMount" || { usuccess=1; show_mount_holders "$readMount"; }
  else
    prompt -w "可读挂载点未挂载: $readMount"
  fi
  sleep 1
  if check_mount_point "$dislockMount"; then
    sudo umount "$dislockMount" || { usuccess=1; show_mount_holders "$dislockMount"; }
  else
    prompt -w "dislocker 挂载点未挂载: $dislockMount"
  fi
  if [ "$usuccess" -eq 0 ]; then
    prompt -s "Disk unmounted successfully."
    rm -f "${STATE_DIR}/.last-readmount" 2>/dev/null || true
    return 0
  fi
  prompt -e "WARN: An error may occur during the umount process, check manual."
  return 1
}

run_interactive() {
  detect_existing_bitlocker_mount || true
  if check_bitlocker_mount; then
    umountBitlocker
    return $?
  fi
  check_bitlocker_mount_adv
  local status=$?
  case $status in
  0)
    echo "BitLocker 磁盘已挂载：两个挂载点都已挂载"
    ;;
  1)
    echo "BitLocker 磁盘已挂载：只挂载了 $readMount ，请手动检查。"
    umountBitlocker
    return 1
    ;;
  2)
    echo "BitLocker 磁盘已挂载：只挂载了 $dislockMount ，请手动检查。"
    umountBitlocker
    return 1
    ;;
  3)
    mountBitlockerDisk
    ;;
  4)
    echo "BitLocker 磁盘状态未知"
    return 1
    ;;
  esac
}

main() {
  case "${1:-}" in
    -h|--help)
      packed_usage
      exit 0
      ;;
    --mount|-m)
      if detect_existing_bitlocker_mount && check_bitlocker_mount; then
        prompt -w "已经挂载: $readMount"
        exit 1
      fi
      run_mount_direct
      exit $?
      ;;
    --umount|-u)
      run_umount_direct
      exit $?
      ;;
    "")
      run_interactive
      exit $?
      ;;
    *)
      prompt -e "未知参数: $1"
      packed_usage
      exit 2
      ;;
  esac
}

main "$@"

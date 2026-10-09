#!/bin/bash
# 直接挂载，不再询问。参数在 config.sh。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
source "$SCRIPT_DIR/config.sh"
if [ "$?" -ne 0 ]; then
  echo "\033[0;31m Source config.sh: An error occurred and exited. \033[0m"
  exit 1
fi
source "$SCRIPT_DIR/Profile.sh"
if [ "$?" -ne 0 ]; then
  echo "\033[0;31m Source Profile.sh: An error occurred and exited. \033[0m"
  exit 1
fi

if [ -n "${DISLOCKER_CUSTOM:-}" ]; then
  DISLOCKER_BIN="$DISLOCKER_CUSTOM"
else
  DISLOCKER_BIN="dislocker"
fi

# 获取用户名
USERNAME="$USER"

## 检查命令是否安装dislocker、fuse
cmdToCheck="dislocker"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
  prompt -w "WARN: "$cmdToCheck" is not installed, try apt install."
  sudo apt install "$cmdToCheck" -y
else
  prompt -i "Command found! : "$cmdToCheck""
fi
cmdToCheck="fusermount"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
  prompt -w "WARN: "$cmdToCheck" is not installed, try apt install."
  sudo apt install "$cmdToCheck" -y
else
  prompt -i "Command found! : "$cmdToCheck""
fi

pinfo=$(sudo blkid | grep "$puid")
tempArgs=($pinfo)
# /dev/sdb4:
tempArgs=${tempArgs[0]}
# /dev/sdb4
pdev=${tempArgs::-1}
echo "磁盘: $pdev"

if [ ! -d "$dislockMount" ]; then
  prompt -x "mkdir $dislockMount"
  sudo mkdir -p "$dislockMount"
else
  if [ "$(ls -A $dislockMount)" ]; then
    prompt -e "Mountpoint $dislockMount is not empty."
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

## 开始解密
prompt -x "Try to mount (sudo "$DISLOCKER_BIN" "$pdev" -u -- "$dislockMount") ..."
if [ "$keyMode" -eq 0 ]; then
  prompt -m "Decryption with password (-u)."
  if [ -n "$keyPass" ]; then
    echo "Using provided Bitlocker password..."
    sudo "$DISLOCKER_BIN" "$pdev" -u"$keyPass" "$dislockMount"
  else
    echo "Enter Bitlocker password when prompted..."
    sudo "$DISLOCKER_BIN" "$pdev" -u -- "$dislockMount"
  fi
elif [ "$keyMode" -eq 1 ]; then
  prompt -m "Decryption with recovery key (-p)."
  if [ -n "$keyPass" ]; then
    echo "Using provided Bitlocker recovery key..."
    sudo "$DISLOCKER_BIN" "$pdev" -p"$keyPass" "$dislockMount"
  else
    echo "Enter Bitlocker password when prompted..."
    sudo "$DISLOCKER_BIN" "$pdev" -p -- "$dislockMount"
  fi
else
  print_result_banner fail "挂载失败" "keyMode 只能是 0 或 1，当前是 $keyMode"
  exit 1
fi

if [ "$?" -ne 0 ]; then
  print_result_banner fail "挂载失败" "解密失败"
  exit 1
fi

vol_label="$(sudo blkid -o value -s LABEL "$dislockMount/dislocker-file" 2>/dev/null || true)"
resolve_media_read_mount "$vol_label" || {
  print_result_banner fail "挂载失败" "定不了访问目录"
  exit 1
}
prepare_empty_mount_dir "$readMount" || {
  print_result_banner fail "挂载失败" "挂载点目录不可用"
  exit 1
}

if ! sudo mount -o loop,uid=$(id -u $USERNAME),gid=$(id -g $USERNAME) "$dislockMount"/dislocker-file "$readMount"; then
  print_result_banner fail "挂载失败" "文件系统没有挂上: $readMount"
  exit 1
fi
save_last_read_mount "$SCRIPT_DIR"
echo
echo "磁盘: ${pdev:-未知}"
echo "卷标: ${vol_label:-无}"
echo "目录: $readMount"
echo "状态: 已挂载"
print_result_banner ok "挂载成功" "$readMount"

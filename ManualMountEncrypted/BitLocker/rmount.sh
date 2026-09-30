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
prompt -i "Get Bitlocker Part: "$pdev"."
prompt -s " => $pdev <="

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

sudo mount -o loop,uid=$(id -u $USERNAME),gid=$(id -g $USERNAME) "$dislockMount"/dislocker-file "$readMount"
save_last_read_mount "$SCRIPT_DIR"
prompt -s "Mounted successfully: $readMount"
prompt -i "Use below to unmount."
echo ""
prompt -s "sudo umount $readMount && sudo umount $dislockMount"
echo ""

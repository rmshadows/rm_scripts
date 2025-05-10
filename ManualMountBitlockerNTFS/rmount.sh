#!/bin/bash
# 银河麒麟系统关闭执行控制功能状态：
# sudo setstatus -f exectl off
# setstatus -p softmode
# 开机自动挂载需要修改fstab（修改前记得备份！）
# <partition> /media/bitlocker fuse.dislocker user-password=<password>,nofail 0 0
# /media/bitlocker/dislocker-file /media/bitlockermount auto nofail 0 0

# Manual
## 获取Bitlocker加密分区
puid="4463e4a8-296b-4db9-aa4d-7c83c762665e"
# /dev/sdb4: TYPE="BitLocker" PARTUUID="4463e4a8-296b-4db9-aa4d-7c83c762665e"
## 新建文件夹（挂载文件夹）
dislockMount="/home/bitlocker"
# 可访问的挂载点
readMount="/media/bitlockermount"
# 解密方式 0:密码 1:恢复密钥
keyMode=0
# Bitlocker磁盘密码(可选) 没有请注释
# keyPass=""
# 指定dislocker
DISLOCKER_BIN="dislocker"
# DISLOCKER_BIN="./UOS-arm64/dislocker"

source Profile.sh
if [ "$?" -ne 0 ]; then
  echo "\033[0;31m Source Profile.sh: An error occurred and exited. \033[0m"
  exit 1
fi

# 获取用户名
USERNAME="$USER"

## 检查命令是否安装dislocker、fuse
cmdToCheck="dislocker"
if ! [ -x "$(command -v "$cmdToCheck")" ]; then
  # echo "Error: "$cmdToCheck" is not installed." >&2
  prompt -w "WARN: "$cmdToCheck" is not installed, try apt install."
  sudo apt install "$cmdToCheck" -y
else
  # echo "Command found! : "$cmdToCheck"" >&1
  prompt -i "Command found! : "$cmdToCheck""
fi
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

if [ ! -d "$readMount" ]; then
  prompt -x "mkdir $readMount"
  sudo mkdir -p "$readMount"
else
  # 检查挂载点是否为空
  if [ "$(ls -A $readMount)" ]; then
    prompt -e "Mountpoint "$readMount" is not empty."
    # 进一步处理，例如列出挂载点的内容
    ls -la "$readMount"
    comfirmn "\e[1;33m Whether to clear $readMount ? (CAN NOT BE UNDONE!) [y/N]\e[0m"
    choice=$?
    if [ $choice == 1 ]; then
      prompt -x "Clear Mountpoint $readMount ..."
      sudo rm -rf "$readMount"
      prompt -x "mkdir $readMount"
      sudo mkdir -p "$readMount"
    elif [ $choice == 2 ]; then
      prompt -w "Quit."
      exit 1
    else
      prompt -e "Unknown option !"
      exit 5
    fi
  fi
fi
## 开始挂载
# sudo "$DISLOCKER_BIN" /dev/sdb4 -u -- /home/bitlocker
# sudo umount /home/bitlocker
prompt -x "Try to mount (sudo "$DISLOCKER_BIN" "$pdev" -u -- "$dislockMount") ..."
if [ "$keyMode" -eq 0 ]; then
  prompt -m "Decryption with password (-u)."
  # 判断是否提供了密码
  if [ -n "$keyPass" ]; then
    # 如果提供了密码，则使用提供的密码解锁
    echo "Using provided Bitlocker password..."
    sudo "$DISLOCKER_BIN" "$pdev" -u"$keyPass" "$dislockMount"
  else
    # 如果未提供密码，则手动输入密码
    echo "Enter Bitlocker password when prompted..."
    sudo "$DISLOCKER_BIN" "$pdev" -u -- "$dislockMount"
  fi
elif [ "$keyMode" -eq 1 ]; then
  prompt -m "Decryption with recovery key (-p)."
  # https://linux.cn/article-14008-1.html
  # 判断是否提供了密码
  if [ -n "$keyPass" ]; then
    # 如果使用的恢复密钥：
    echo "Using provided Bitlocker recovery key..."
    sudo "$DISLOCKER_BIN" "$pdev" -p"$keyPass" "$dislockMount"
  else
    # 如果未提供密码，则手动输入密码
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

# 下一个命令是把解密好的分区挂在到bitlockermount loop:用来把一个文件当成硬盘分区挂接上系统
# ,uid=$(id -u ryan),gid=$(id -g ryan) 能解决回收站无法使用的问题 sudo mount -o loop,uid=$(id -u ryan),gid=$(id -g ryan) "$dislockMount"/dislocker-file "$readMount"
sudo mount -o loop,uid=$(id -u $USERNAME),gid=$(id -g $USERNAME) "$dislockMount"/dislocker-file "$readMount"
# sudo mount -o loop "$dislockMount"/dislocker-file "$readMount"
prompt -s "Mounted successfully."
# echo "Launched."
# echo "Use below to unmount."
prompt -i "Use below to unmount."
echo ""
prompt -s "sudo umount "$dislockMount""
# echo "sudo umount "$dislockMount""
echo ""

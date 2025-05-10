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
# 可选指定 dislocker 路径（适用于 UOS arm64，系统自带 dislocker 可能有问题）
# DISLOCKER_CUSTOM="./UOS-arm64/dislocker"
# DISLOCKER_CUSTOM="./amd64/dislocker"

# 内部参数
DISLOCKER_BIN=""
source Profile.sh
if [ "$?" -ne 0 ]; then
    echo "\033[0;31m Source Profile.sh: An error occurred and exited. \033[0m"
    exit 1
fi

# 函数：检查单个挂载点是否挂载
check_mount_point() {
    local mount_point="$1"

    if grep -qs "$mount_point" /proc/mounts; then
        return 0 # 已挂载
    else
        return 1 # 未挂载
    fi
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
    comfirmy "\e[1;33m BitLocker disk mounted.Umount ? [Y/n]\e[0m"
    choice=$?
    usuccess=0
    if [ $choice == 1 ]; then
        sudo umount "$readMount"
        if [ "$?" -ne 0 ] && [ "$usuccess" -eq 0 ]; then
            usuccess=1
        fi
        sleep 1
        sudo umount "$dislockMount"
        if [ "$?" -ne 0 ] && [ "$usuccess" -eq 0 ]; then
            usuccess=1
        fi
    elif [ $choice == 2 ]; then
        prompt -i "Quit."
    else
        prompt -e "ERROR:未知返回值!"
        exit 5
    fi
    if [ "$usuccess" -eq 0 ]; then
        prompt -s "Disk unmounted successfully."
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
    elif [ $choice == 2 ]; then
        prompt -i "Quit."
    else
        prompt -e "ERROR:未知返回值!"
        exit 5
    fi
}

# 检查 BitLocker 磁盘是否挂载
if check_bitlocker_mount; then
    umountBitlocker
else
    check_bitlocker_mount_adv
    status=$?
    case $status in
    0)
        echo "BitLocker 磁盘已挂载：两个挂载点都已挂载"
        ;;
    1)
        echo "BitLocker 磁盘已挂载：只挂载了 $readMount ，请手动检查。"
        umountBitlocker
        exit 1
        ;;
    2)
        echo "BitLocker 磁盘已挂载：只挂载了 $dislockMount ，请手动检查。"
        umountBitlocker
        exit 1
        ;;
    3)
        mountBitlockerDisk
        ;;

    4)
        echo "BitLocker 磁盘状态未知"
        ;;
    esac
fi

#!/bin/bash
: <<!说明
末尾运行
设置 GRUB os-prober
设置用户目录权限
!说明

# 设置 GRUB os-prober
if [ "$SET_ENABLE_GRUB_OS_PROBER" -eq 0 ]; then
    # 不做处理
    prompt -m "GRUB os-prober 保持默认。"
elif [ "$SET_ENABLE_GRUB_OS_PROBER" -eq 2 ]; then
    # Sample:查找字段整行替换
    # 启用 os-prober
    # 配置/etc/default/grub 参数：GRUB_DISABLE_OS_PROBER=false
    prompt -m "禁用 GRUB os-prober 。"
    prompt -m "检查 /etc/default/grub 中os-prober是否启用..."
    check_file="/etc/default/grub"
    backupFile "$check_file"
    check_var="^GRUB_DISABLE_OS_PROBER=true"
    if sudo cat "$check_file" | grep "$check_var" >/dev/null; then
        echo -e "\e[1;34m请检查文件内容：
===============================================================\e[0m"
        sudo cat "$check_file"
        prompt -w "GRUB os-prober 似乎已禁用（如上所列），不做处理。"
    else
        check_var="^GRUB_DISABLE_OS_PROBER="
        # 获取行号
        idx=$(sudo cat "$check_file" | grep -n ^$check_var | gawk '{print $1}' FS=":")
        # 找到的Index
        idxl=($idx)
        idxlen=${#idxl[@]}
        # echo $idxlen
        I_STRING="GRUB_DISABLE_OS_PROBER=true"
        if [ $idxlen -eq 1 ]; then
            # 删除行
            sed -i "$idx d" "$check_file"
            # 在前面插入
            sed -i "$idx i $I_STRING" "$check_file"
        elif [ $idxlen -eq 0 ]; then
            prompt -w "Setting not found in "$check_file"!"
            echo $I_STRING | sudo tee -a "$check_file"
        else
            prompt -e "Find duplicate parameter "check_var" in "$check_file"! Check manually!"
            exit 1
        fi
        sudo update-grub
    fi
elif [ "$SET_ENABLE_GRUB_OS_PROBER" -eq 1 ]; then
    # 启用 os-prober
    # 配置/etc/default/grub 参数：GRUB_DISABLE_OS_PROBER=false
    prompt -m "启用 GRUB os-prober 。"
    prompt -m "检查 /etc/default/grub 中os-prober是否启用..."
    check_file="/etc/default/grub"
    backupFile "$check_file"
    check_var="^GRUB_DISABLE_OS_PROBER=false"
    if sudo cat "$check_file" | grep "$check_var" >/dev/null; then
        echo -e "\e[1;34m请检查文件内容：
===============================================================\e[0m"
        sudo cat "$check_file"
        prompt -w "GRUB os-prober 似乎已启用（如上所列），不做处理。"
    else
        check_var="^GRUB_DISABLE_OS_PROBER="
        # 获取行号
        idx=$(sudo cat "$check_file" | grep -n ^$check_var | gawk '{print $1}' FS=":")
        # 找到的Index
        idxl=($idx)
        idxlen=${#idxl[@]}
        # echo $idxlen
        I_STRING="GRUB_DISABLE_OS_PROBER=false"
        if [ $idxlen -eq 1 ]; then
            # 删除行
            sed -i "$idx d" "$check_file"
            # 在前面插入
            sed -i "$idx i $I_STRING" "$check_file"
        elif [ $idxlen -eq 0 ]; then
            prompt -w "Setting not found in "$check_file"!"
            echo $I_STRING | sudo tee -a "$check_file"
        else
            prompt -e "Find duplicate parameter "check_var" in "$check_file"! Check manually!"
            exit 1
        fi
        sudo update-grub
    fi
fi

# 设置用户目录权限
if [ "$SET_USER_HOME" -eq 1 ]; then
    prompt -x "设置用户目录权限"
    sudo chown $CURRENT_USER -hR /home/$CURRENT_USER
    sudo chmod 700 /home/$CURRENT_USER
    if [ -f "/home/$CURRENT_USER/nginx" ]; then
        sudo setfacl -m u:www-data:rx /home/$CURRENT_USER
        sudo setfacl -R -m u:www-data:rx /home/$CURRENT_USER/nginx
    elif [ -f "/home/$CURRENT_USER/apache2" ]; then
        sudo setfacl -m u:www-data:rx /home/$CURRENT_USER
        sudo setfacl -R -m u:www-data:rx /home/$CURRENT_USER/apache2
    fi
fi

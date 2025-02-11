#!/bin/bash
# 备份数据，注意：此脚本的运行至少间隔1秒!
# 用途：备份文件夹
# 版本：0.0.2 
# 2022年 12月 06日 星期二 15:42:45 CST
# Log
# 0.0.1 初始版本
# 0.0.2 待备份数据大小判断

# 参数Manual
# 显示详情请取消注释下行
# set -uex
# 要备份的文件夹
TO_BACKUP_DDIR=data
# 储存备份文件的文件夹
BACKUP_DDIR=DateBackups
# 限制备份目录大小（请使用KB Kilobyte 1048576KB=1GB）
BACKUP_DDIR_LIMIT=524288
# 是否直接删除多余备份 (1 是 其他:请指定到回收目录)
RM_BACKUPS_DIRECTLY=1

#################################################
# 内部参数
BACKUP_TIME=$(date +%Y-%m-%d#%H:%M:%S)
# 递归次数
COUNTS=0
# 递归深度限制
RECU_DEP=100

# 内部函数
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
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    *)
    echo -e "$@"
    ;;
  esac
}

# 获取文件夹大小 KB
getSize() {    
    getSizeResult=`du -s $1 | awk '{print $1}'`
    if [ "$?" -ne 0 ];then
        prompt -e "getSizeResult赋值错误，使用gawk..."
        getSizeResult=`du -s $1 | gawk '{print $1}'`
    fi
    if [ -d "$1" ];then
        getSizeResult=$((getSizeResult-4))
    fi
}

# 检查备份目录大小，删除多余备份
reduceBackups() {
    COUNTS=$(($COUNTS+1))
    if [ "$COUNTS" -ge "$RECU_DEP" ];then
        prompt -e "reduceBackups:递归深度超出设定的$RECU_DEP (现在：$COUNTS)"
        exit 1
    fi
    if [ "$RM_BACKUPS_DIRECTLY" -ne 1 ];then
        if ! [ -d "$RM_BACKUPS_DIRECTLY" ];then
            prompt -e "$RM_BACKUPS_DIRECTLY 不是一个文件夹，请提供回收目录！"
            exit 1
        fi
        # TODO:这里还需要判断回收目录是否位于备份文件夹中
    fi
    # 检查备份文件夹大小 kb
    getSize $BACKUP_DDIR
    if [ "$getSizeResult" -ge "$BACKUP_DDIR_LIMIT" ];then
        prompt -w "备份目录$BACKUP_DDIR 大小($getSizeResult KB)超出了限制($BACKUP_DDIR_LIMIT KB)。"
        # 开始删除多余备份
        EARLY_BACKUP=`ls "$BACKUP_DDIR" | sort | sed -n '1p'`
        # 2022-12-06#02:04:50处理成20221206 02:04:50格式
        date1=`echo "$EARLY_BACKUP" | sed s/-//g | sed s/\#/\ /g`
        date1=`date -d "$date1" +%s`
        all_backups=(`ls "$BACKUP_DDIR"`)
        prompt -w "当前共有 ${#all_backups[@]} 个备份。"
        getEarlyBackup "$EARLY_BACKUP"
        EARLY_BACKUP="$getEarlyBackupResult"
        prompt -w  "找到最早的备份: $EARLY_BACKUP"
        if [ "$RM_BACKUPS_DIRECTLY" -eq 1 ];then
            prompt -w "$EARLY_BACKUP 将被删除"
            rm -r "$BACKUP_DDIR/$EARLY_BACKUP"
        else
            prompt -w "$EARLY_BACKUP 已回收至 $RM_BACKUPS_DIRECTLY"
            mv "$BACKUP_DDIR/$EARLY_BACKUP" "$RM_BACKUPS_DIRECTLY"
        fi
        if [ "$?" -ne 0 ];then
            prompt -e "reduceBackups出错！"
            exit 1
        fi
        reduceBackups
    else
        prompt -i "当前备份已使用: $getSizeResult KB (限值：$BACKUP_DDIR_LIMIT KB)"
    fi
}

# 检查所给的日期(备份文件夹名)是否是最早备份的日期 返回 最早的备份
getEarlyBackup() {
    COUNTS=$(($COUNTS+1))
    if [ "$COUNTS" -ge "$RECU_DEP" ];then
        prompt -e "getEarlyBackup:递归深度超出设定的$RECU_DEP (现在：$COUNTS)"
        exit 1
    fi
    temp=$1
    all_backups=(`ls "$BACKUP_DDIR"`)
    date1=`echo "$temp" | sed s/-//g | sed s/\#/\ /g`
    date1=`date -d "$date1" +%s`
    # 循环比较 
    for each in ${all_backups[@]};do
        # 2022-12-06#02:04:50处理成20221206 02:04:50格式
        date2=`echo "$each" | sed s/-//g | sed s/\#/\ /g`
        # date2是用于比较的
        date2=`date -d "$date2" +%s`
        # 如果date1大于date2 （那就是不对的）
        if [ "$date1" -gt "$date2" ];then
            # 如果date1大于date2说明date2更早
            temp=$each
            getEarlyBackup "$temp"
        fi
    done
    getEarlyBackupResult=$temp
}

#### Pre-required
if ! [ -x "$(command -v du)" ]; then
  echo 'Error: du is not installed.' >&2
  sudo apt install coreutils
fi
if ! [ -x "$(command -v awk)" ]; then
  echo 'Error: awk is not installed.' >&2
  sudo apt install gawk
fi
if ! [ -d "$BACKUP_DDIR" ];then
    prompt -e "$BACKUP_DDIR 文件夹不存在"
    exit 1
fi

#### 正文
# 检查待备份文件夹大小 kb
getSize $TO_BACKUP_DDIR
prompt -i "待备份数据: $getSizeResult KB"
if [ "$getSizeResult" -ge "$BACKUP_DDIR_LIMIT" ];then
    prompt -e "待备份数据大小大于备份目录限制！"
    exit 1
fi
prompt -i "开始备份至$BACKUP_DDIR/$BACKUP_TIME...."
cp -r "$TO_BACKUP_DDIR" "$BACKUP_DDIR/$BACKUP_TIME"
if [ "$?" -ne 0 ];then
    prompt -e "——备份出错，请检查！！"
    exit 1
else
    prompt -s "——备份完成——"
fi
# 检查备份目录大小
reduceBackups
COUNTS=0

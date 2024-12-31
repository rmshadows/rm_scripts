#!/bin/bash
# 前提：sudo命令无需输入密码
# 功能：运行sudo cancel -a取消所有打印任务
# 快捷键：Alt+Shift+P
# 使用：gnome-terminal -- "Path to Cancel_All_Print_Task.sh"


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

print_comfirm () {
  flag=true
  while $flag
  do
    echo -en "\033[1;31m WARN: ALL PRINT TASK WILL BE CANCELED ! \033[1;33m"
    if read -t 5 -p "Sure to send to printer ? (Y/n) " input
    then 
      if [ -z "${input}" ];then
        input='y'
      fi
    else 
      prompt -e "\n\nERROR: Timeout, quit[1]. Canceled and released !"
      exit 1 
    fi
    case $input in [yY][eE][sS]|[yY])
      sudo cancel -a
      prompt -i "All jobs have been released! "
      sleep 2
      flag=false
    ;;
    [nN][oO]|[nN])
      exit 0
      flag=false
    ;;
    *)
      prompt -w "Invalid input..."
    ;;
    esac
  done
}


print_comfirm


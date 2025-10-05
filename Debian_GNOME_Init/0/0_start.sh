#!/bin/bash
:<<!说明
脚本开头(升级发行版需要更新检测发行版的代码)
任务：
检查运行环境
!说明


echo -e "\e[1;31m
_________  .___ ____   ____.___ _________  _________  _________  _________  _________  
\_   ___ \ |   |\   \ /   /|   |\_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ \_   ___ \ 
/    \  \/ |   | \   Y   / |   |/    \  \/ /    \  \/ /    \  \/ /    \  \/ /    \  \/ 
\     \____|   |  \     /  |   |\     \____\     \____\     \____\     \____\     \____
 \______  /|___|   \___/   |___| \______  / \______  / \______  / \______  / \______  /
        \/                              \/         \/         \/         \/         \/ 
\e[1;32m
==========================================
┏ ^ǒ^*★*^ǒ^*☆*^ǒ^*★*^ǒ^*☆*^ǒ^★*^ǒ^*☆*^ǒ^ ┓ 
┃        欢迎使用Debian部署脚本          ┃
┗ ^ǒ^*★*^ǒ^*☆*^ǒ^*★*^ǒ^*☆*^ǒ^★*^ǒ^*☆*^ǒ^ ┛ 
==========================================

\e[0m"

# 检测到苹果系统，退出
if [ -e /usr/bin/uname ]; then
    if [ "`/usr/bin/uname -s`" = "Darwin" ]; then
        prompt -e '*** Detected MacOS / Darwin, quit!'
        prompt -e '*** Linux only!'
        exit 0
    fi
fi

# 检测Linux发行版
prompt -w '*** Detecting Linux Distribution....'
if [ -f /etc/debian_version ]; then
    dvers=`cat /etc/debian_version | cut -d '.' -f 1 | cut -d '/' -f 1`
    if [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F -i LinuxMint`" ]; then
        # Linux Mint -> Ubuntu 'xenial'
        prompt -w '*** Found Linux Mint      Ubuntu xenial'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F trusty`" ]; then
        # Ubuntu 'trusty'
        prompt -w '*** Found Ubuntu      trusty'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F wily`" ]; then
        # Ubuntu 'wily'
        prompt -w '*** Found Ubuntu      wily'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F xenial`" ]; then
        # Ubuntu 'xenial'
        prompt -w '*** Found Ubuntu      xenial'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F zesty`" ]; then
        # Ubuntu 'zesty'
        prompt -w '*** Found Ubuntu      zesty'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F precise`" ]; then
        # Ubuntu 'precise'
        prompt -w '*** Found Ubuntu      recise'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F artful`" ]; then
        # Ubuntu 'artful'
        prompt -w '*** Found Ubuntu      artful'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F bionic`" ]; then
        # Ubuntu 'bionic'
        prompt -w '*** Found Ubuntu      bionic'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F yakkety`" ]; then
        # Ubuntu 'yakkety'
        prompt -w '*** Found Ubuntu      yakkety'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F disco`" ]; then
        # Ubuntu 'disco'
        prompt -w '*** Found Ubuntu      disco'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F focal`" ]; then
        # Ubuntu 'focal' -> Ubuntu 'bionic' (for now)
        prompt -w '*** Found Ubuntu      focal->bionic'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F hirsute`" ]; then
        # Ubuntu 'hirsute' -> Ubuntu 'bionic' (for now)
        prompt -w '*** Found Ubuntu      hirsute->bionic'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ -f /etc/lsb-release -a -n "`cat /etc/lsb-release 2>/dev/null | grep -F impish`" ]; then
        # Ubuntu 'impish' -> Ubuntu 'bionic' (for now)
        prompt -w '*** Found Ubuntu      impish->bionic'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ "$dvers" = "6" -o "$dvers" = "squeeze" ]; then
        # Debian 'squeeze'
        prompt -w '*** Found Debian      squeeze'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ "$dvers" = "7" -o "$dvers" = "wheezy" ]; then
        # Debian 'wheezy'
        prompt -w '*** Found Debian      wheezy'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ "$dvers" = "8" -o "$dvers" = "jessie" ]; then
        # Debian 'jessie'
        prompt -w '*** Found Debian      jessie'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ "$dvers" = "9" -o "$dvers" = "stretch" ]; then
        # Debian 'stretch'
        prompt -w '*** Found Debian      '
    elif [ "$dvers" = "10" -o "$dvers" = "buster" ]; then
        # Debian 'buster'
        prompt -w '*** Found Debian      buster'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ "$dvers" = "11" -o "$dvers" = "bullseye" ]; then
        # Debian 'bullseye'
        prompt -w '*** Found Debian      bullseye'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ "$dvers" = "12" -o "$dvers" = "bookworm" ]; then
        # Debian 'bookworm'
        prompt -s '*** Found Debian      bookworm'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    elif [ "$dvers" = "13" -o "$dvers" = "trixie" ]; then
        # Debian 'trixie'
        prompt -s '*** Found Debian      trixie'
    elif [ "$dvers" = "testing" -o "$dvers" = "sid" -o "$dvers" = "forky" ]; then
        # Debian 'testing', 'sid'
        prompt -s '*** Found Debian      testing'
        prompt -w "*** WARN: Debian testing 或 sid，请谨慎使用！"
    else
        # Use Debian "buster" for unrecognized Debians
        prompt -w '*** Found Debian or Debian derivative      unrecognized Debians'
        prompt -w "*** WARN: 非本脚本指定的发行版，谨慎使用！ Not for this distribution, use with caution !"
    fi
elif [ -f /etc/SuSE-release -o -f /etc/suse-release -o -f /etc/SUSE-brand -o -f /etc/SuSE-brand -o -f /etc/suse-brand ]; then
    prompt -e '*** Found SuSE, required zypper YUM repo...'
    prompt -e '*** Debian only !'
    exit 1
elif [ -d /etc/yum.repos.d ]; then
    if [ -n "`cat /etc/redhat-release 2>/dev/null | grep -i fedora`" ]; then
        prompt -e "*** Found Fedora, required /etc/yum.repos.d/xxx.repo"
        prompt -e '*** Debian only !'
        exit 1
    elif [ -n "`cat /etc/redhat-release 2>/dev/null | grep -i centos`" -o -n "`cat /etc/redhat-release 2>/dev/null | grep -i enterprise`" ]; then
        prompt -e "*** Found RHEL/CentOS, required /etc/yum.repos.d/xxx.repo"
        prompt -e '*** Debian only !'
        exit 1
    elif [ -n "`cat /etc/system-release 2>/dev/null | grep -i amazon`" ]; then
        prompt -e "*** Found Amazon (CentOS/RHEL based), required /etc/yum.repos.d/xxx.repo"
        if [ -n "`cat /etc/system-release 2>/dev/null | grep -F 'Amazon Linux 2'`" ]; then
            prompt -e '*** Debian only, NOT redhat/el/7 !'
            exit 1
        else
            prompt -e '*** Debian only, NOT redhat/amzn1/2016.03 !'
            exit 1
        fi
    else
        prompt -e "*** Found unknown yum-based repo, using el/7"
        prompt -e '*** Debian only !'
        exit 1
    fi
fi


# R
echo -e "\e[1;31m接下来请根据提示进行操作，正在准备(1s)...\n\e[0m"
sleep 1

### 预先检查
# 检查是否有root权限，有则退出，提示用户使用普通用户权限。
prompt -i "\n检查权限  ——    Checking for root access...\n"
if [ "$UID" -eq "$ROOT_UID" ]; then
    # Error message
    prompt -e "\n [ Error ] -> 请不要使用管理员权限运行 Please DO NOT run as root  \n"
    exit 1
else
    prompt -w "\n——————————  Unit Ready  ——————————\n"
fi

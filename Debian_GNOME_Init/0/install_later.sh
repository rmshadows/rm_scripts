#!/bin/bash
: <<!说明
此脚本用于脚本执行末尾安装软件
!说明


## 下面是滞后的步骤
:<<安装时间较长的软件包
VirtualBox
Anydesk
typora
sublime text
teamviewer
wps-office
skype
docker-ce
安装网易云音乐
禁用第三方软件仓库更新(提升apt体验)
安装时间较长的软件包
# 安装later_task中的软件
if [ "$SET_APT_INSTALL" -eq 1 ];then
    doApt install ${later_task[@]}
    if [ $? != 0 ];then
        prompt -e "安装出错，列表中有仓库中没有的软件包。下面将进行逐个安装，按任意键继续。"
        sleep 2
        num=1
        for var in ${later_task[@]}
        do
            prompt -m "正在安装第 $num 个软件包: $var。"
            doApt install $var
            num=$((num+1))
        done
    fi 
fi

# 安装Virtual Box
if [ "$SET_INSTALL_VIRTUALBOX" -eq 1 ];then
    prompt -x "安装Virtual Box"
    if ! [ -x "$(command -v virtualbox)" ]; then
        prompt -m "检查是否为Sid源"
        is_debian_sid=0
        sid_var1="debian/ sid main"
        sid_var2="debian sid main"
        if sudo cat '/etc/apt/sources.list' | grep "$sid_var1" > /dev/null
        then
            is_debian_sid=1
        fi
        if sudo cat '/etc/apt/sources.list' | grep "$sid_var2" > /dev/null
        then
            is_debian_sid=1
        fi
        if [ "$is_debian_sid" -eq 1 ];then
            prompt -m "检测到使用的是Debian sid源，直接从源安装"
            doApt install virtualbox
        else
            if [ "$SET_VIRTUALBOX_REPO" -eq 0 ];then
                prompt -m "不是sid源，添加官方仓库"
                # https://suay.site/?p=526
                sudo curl https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/oracle_vbox_2016.asc.gpg --import
                sudo chmod 644 /etc/apt/trusted.gpg.d/oracle_vbox_2016.asc.gpg
                # wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
                # wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
                sudo echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian bookworm contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
            elif [ "$SET_VIRTUALBOX_REPO" -eq 1 ];then
                prompt -m "不是sid源，添加清华大学镜像仓库"
                curl https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/oracle_vbox_2016.asc.gpg --import
                sudo chmod 644 /etc/apt/trusted.gpg.d/oracle_vbox_2016.asc.gpg
                # wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
                sudo echo "deb http://mirrors.tuna.tsinghua.edu.cn/virtualbox/apt/ bookworm contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
            fi
            doApt update
            doApt install virtualbox
        fi
    else
        prompt -m "您可能已经安装了VirtualBox"
    fi
    prompt -x "添加用户到vboxusers组"
    sudo usermod -aG vboxusers $CURRENT_USER
fi

# 安装Anydesk
if [ "$SET_INSTALL_ANYDESK" -eq 1 ];then
    if ! [ -x "$(command -v anydesk)" ]; then
        prompt -x "安装Anydesk"
        curl https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/anydesk.gpg --import
        sudo chmod 644 /etc/apt/trusted.gpg.d/anydesk.gpg
        # wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | apt-key add -
        sudo echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
        doApt update
        doApt install anydesk
    else
        prompt -m "您可能已经安装了Anydesk"
    fi
    if [ "$SET_ENABLE_ANYDESK" -eq 0 ];then
        prompt -x "禁用Anydesk服务开机自启"
        sudo systemctl disable anydesk.service
    elif [ "$SET_ENABLE_ANYDESK" -eq 1 ];then
        prompt -x "配置Anydesk服务开机自启"
        sudo systemctl enable anydesk.service
    fi
fi

# 安装typora
if [ "$SET_INSTALL_TYPORA" -eq 1 ];then
    if ! [ -x "$(command -v typora)" ]; then
        prompt -x "安装typora"
        curl https://typora.io/linux/public-key.asc | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/typora.gpg --import
        sudo chmod 644 /etc/apt/trusted.gpg.d/typora.gpg
        sudo echo "deb https://typora.io/linux ./" | sudo tee /etc/apt/sources.list.d/typora.list
        doApt update
        doApt install typora
    else
        prompt -m "您可能已经安装了Typora"
    fi
fi

# 安装sublime-text
if [ "$SET_INSTALL_SUBLIME_TEXT" -eq 1 ];then
    if ! [ -x "$(command -v sublime-text)" ]; then
        prompt -x "安装sublime-text"
        curl https://download.sublimetext.com/sublimehq-pub.gpg | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/sublimehq-pub.gpg --import
        sudo chmod 644 /etc/apt/trusted.gpg.d/sublimehq-pub.gpg
        sudo echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
        doApt update
        doApt install sublime-text
    else
        prompt -m "您可能已经安装了Sublime"
    fi
fi

# 安装Teamviewer
if [ "$SET_INSTALL_TEAMVIEWER" -eq 1 ];then
    if ! [ -x "$(command -v teamviewer)" ]; then
        prompt -x "安装teamviewer"
        wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
        doApt install ./teamviewer_amd64.deb
    else
        prompt -m "您可能已经安装了Teamviewer"
    fi
    if [ "$SET_ENABLE_TEAMVIEWER" -eq 0 ];then
        prompt -x "禁用Teamviewer服务开机自启"
        sudo systemctl disable teamviewerd.service
    elif [ "$SET_ENABLE_TEAMVIEWER" -eq 1 ];then
        prompt -x "配置Teamviewer服务开机自启"
        sudo systemctl enable teamviewerd.service
    fi
fi

# 安装skype
if [ "$SET_INSTALL_SKYPE" -eq 1 ];then
    if ! [ -x "$(command -v skypeforlinux)" ]; then
        prompt -x "安装Skype国际版"
        wget https://go.skype.com/skypeforlinux-64.deb
        doApt install ./skypeforlinux-64.deb
    else
        prompt -m "您可能已经安装了Skype"
    fi
fi

# 安装Docker-ce
if [ "$SET_INSTALL_TEAMVIEWER" -eq 1 ];then
    if ! [ -x "$(command -v docker)" ]; then
        prompt -x "安装Docker-ce"
        prompt -x "卸载旧版本"
        sudo doApt remove docker docker-engine docker.io
        if [ "$SET_DOCKER_CE_REPO" -eq 0 ];then
            prompt -m "添加官方仓库"
            # # /usr/share/keyrings/docker-archive-keyring.gpg
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
            sudo chmod 644 /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
            sudo echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        elif [ "$SET_DOCKER_CE_REPO" -eq 1 ];then
            prompt -m "添加清华大学镜像仓库"
            curl https://download.docker.com/linux/debian/gpg | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/docker-archive-keyring.gpg --import
            sudo chmod 644 /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
            sudo echo \
       "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian \
       $(lsb_release -cs) \
       stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi
        doApt update
        doApt install docker-ce # docker-ce-cli containerd.io
    else
        prompt -m "您可能已经安装了Docker"
    fi
    if [ "$SET_ENABLE_DOCKER_CE" -eq 0 ];then
        prompt -x "禁用docker-ce服务开机自启"
        sudo systemctl disable docker.service
    elif [ "$SET_ENABLE_DOCKER_CE" -eq 1 ];then
        prompt -x "配置docker-ce服务开机自启"
        sudo systemctl enable docker.service
    fi
fi

# 安装wps-office
if [ "$SET_INSTALL_WPS_OFFICE" -eq 1 ];then
    if ! [ -x "$(command -v wps)" ]; then
        prompt -x "安装wps-office"
        # wget https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/9615/wps-office_11.1.0.9615_amd64.deb
        # 较稳定版本
        # wget https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/10161/wps-office_11.1.0.10161_amd64.deb
        wget https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/10702/wps-office_11.1.0.10702_amd64.deb
        doApt install ./wps-office*amd64.deb
    else
        prompt -m "您可能已经安装了WPS"
    fi
fi

# 安装网易云音乐
if [ "$SET_INSTALL_NETEASE_CLOUD_MUSIC" -eq 1 ];then
    if ! [ -x "$(command -v netease-cloud-music)" ]; then
        prompt -x "安装网易云音乐"
        wget https://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb
        doApt install ./netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb
    else
        prompt -m "您可能已经安装了netease-cloud-music"
    fi
fi

# 安装Google Chrome（中国）
if [ "$SET_INSTALL_GOOGLE_CHROME" -eq 1 ];then
    if ! [ -x "$(command -v google-chrome)" ]; then
        prompt -x "安装谷歌浏览器(中国大陆专用，其他地区未测试过)"
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        doApt install ./google-chrome-stable_current_amd64.deb
    else
        prompt -m "您可能已经安装了谷歌浏览器"
    fi
fi


#### 禁用第三方仓库更新
if [ "$SET_DISABLE_THIRD_PARTY_REPO" -eq 1 ];then
    prompt -x "禁用第三方软件仓库更新"
    addFolder /etc/apt/sources.list.d/backup
    sudo mv /etc/apt/sources.list.d/* /etc/apt/sources.list.d/backup/
fi



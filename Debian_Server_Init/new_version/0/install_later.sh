#!/bin/bash
: <<!说明
此脚本用于脚本执行末尾安装软件
!说明


## 下面是滞后的步骤
:<<安装时间较长的软件包
docker-ce
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


#### 禁用第三方仓库更新
if [ "$SET_DISABLE_THIRD_PARTY_REPO" -eq 1 ];then
    prompt -x "禁用第三方软件仓库更新"
    addFolder /etc/apt/sources.list.d/backup
    sudo mv /etc/apt/sources.list.d/* /etc/apt/sources.list.d/backup/
fi



#!/bin/bash
: <<!说明
此脚本用于脚本执行末尾安装软件
!说明

## 下面是滞后的步骤
: <<安装时间较长的软件包
docker-ce
禁用第三方软件仓库更新(提升apt体验)
安装时间较长的软件包
# 安装later_task中的软件
if [ "$SET_APT_INSTALL" -eq 1 ]; then
    doApt install "${later_task[@]}"
    if [ $? != 0 ]; then
        prompt -e "安装出错，列表中有仓库中没有的软件包。下面将进行逐个安装，按任意键继续。"
        sleep 2
        num=1
        for var in "${later_task[@]}"; do
            prompt -m "正在安装第 $num 个软件包: $var。"
            doApt install $var
            num=$((num + 1))
        done
    fi
fi

# https://docs.docker.com/engine/install/
# https://download.docker.com/linux/debian/dists/
# https://download.docker.com/linux/debian/dists/bookworm/pool/stable/
# https://get.docker.com/
# curl -fsSL https://get.docker.com -o get-docker.sh
# sudo sh ./get-docker.sh --dry-run
# 如果安装失败可以考虑使用:
# curl -fsSL https://get.docker.com -o get-docker.sh
# sudo sh get-docker.sh
# Executing docker install script, commit: 7cae5f8b0decc17d6571f9f52eb840fbc13b2737
# <...>
# 安装Docker-ce
if [ "$SET_INSTALL_DOCKER_CE" -eq 1 ]; then
    doApt remove docker docker-engine docker.io
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do doApt remove $pkg; done
    if [ "$SET_DOCKER_PURGE_REINSTALL" -eq 0 ]; then
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do doApt remove $pkg; done
        # 彻底清除Docker
        for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras; do doApt purge $pkg; done
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd
        sudo rm /etc/apt/sources.list.d/docker.list
        sudo rm /etc/apt/keyrings/docker.asc
    fi
    if ! [ -x "$(command -v docker)" ]; then
        prompt -x "安装Docker-ce"
        prompt -x "卸载旧版本"
        doApt remove docker docker-engine docker.io
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do doApt remove $pkg; done
        if [ "$SET_DOCKER_CE_REPO" -eq 0 ]; then
            prompt -m "添加官方仓库"
            # Add Docker's official GPG key:
            doApt update
            doApt install ca-certificates curl
            sudo install -m 0755 -d /etc/apt/keyrings
            # 如果由于网络原因，手动配置了/etc/apt/keyrings/docker.asc，则注释下面这句
            # 或者 https://mirrors.aliyun.com/docker-ce/linux/debian/gpg
            # sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            if ! sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc; then
                echo "主源下载失败，尝试使用阿里云镜像..."
                sudo curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            fi
            sudo chmod a+r /etc/apt/keyrings/docker.asc
            # Add the repository to Apt sources:
            # 如果您使用的衍生物的分布，如卡利Linux， 你可能需要的替代品的一部分，这个命令，该命令的期望 打印的版本代号：
            # 读取 /etc/os-release 文件，加载其中的环境变量.然后输出 VERSION_CODENAME 变量的值，即操作系统版本的代号。
            # $(. /etc/os-release && echo "$VERSION_CODENAME") 替换这部分与代号相应Debian释放， 如 bookworm.
            # Add the repository to Apt sources:
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        elif [ "$SET_DOCKER_CE_REPO" -eq 1 ]; then
            prompt -m "添加清华大学镜像仓库"
            if ! sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc; then
                echo "主源下载失败，尝试使用阿里云镜像..."
                sudo curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            fi
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi
        doApt update
        doApt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        prompt -m "您可能已经安装了Docker，跳过"
    fi
    # sudo docker run hello-world
    # If you initially ran Docker CLI commands using sudo before adding your user to the docker group, you may see the following error:
    # WARNING: Error loading config file: /home/user/.docker/config.json -
    # stat /home/user/.docker/config.json: permission denied
    # This error indicates that the permission settings for the ~/.docker/ directory are incorrect, due to having used the sudo command earlier.
    # To fix this problem, either remove the ~/.docker/ directory (it's recreated automatically, but any custom settings are lost), or change its ownership and permissions using the following commands:
    # sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
    # sudo chmod g+rwx "$HOME/.docker" -R
    if [ "$SET_DOCKER_NON_ROOT" -eq 1 ]; then
        sudo groupadd docker
        sudo usermod -aG docker $CURRENT_USER
        newgrp docker
    fi
    if [ "$SET_ENABLE_DOCKER_CE" -eq 0 ]; then
        prompt -x "禁用docker-ce服务开机自启"
        sudo systemctl disable docker.service
        sudo systemctl disable containerd.service
    elif [ "$SET_ENABLE_DOCKER_CE" -eq 1 ]; then
        prompt -x "配置docker-ce服务开机自启"
        sudo systemctl enable docker.service
        sudo systemctl enable containerd.service
    fi
fi

#### 禁用第三方仓库更新
if [ "$SET_DISABLE_THIRD_PARTY_REPO" -eq 1 ]; then
    prompt -x "禁用第三方软件仓库更新"
    addFolder /etc/apt/sources.list.d/backup
    # 定义保护文件（白名单）
    PROTECT_LIST=(
        "debian.sources"
        "debian.list"
    )
    for f in /etc/apt/sources.list.d/*; do
        [ -e "$f" ] || continue
        basename=$(basename "$f")
        # 判断是否在保护列表中
        skip=0
        for p in "${PROTECT_LIST[@]}"; do
            if [ "$basename" = "$p" ]; then
                skip=1
                break
            fi
        done
        # 非保护文件则移动到 backup
        if [ $skip -eq 0 ]; then
            sudo mv "$f" /etc/apt/sources.list.d/backup/
        fi
    done
fi

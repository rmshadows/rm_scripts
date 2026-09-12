#!/bin/bash
: <<!说明
此脚本用于脚本执行末尾安装软件
!说明

## 下面是滞后的步骤
: <<安装时间较长的软件包
docker-ce
禁用第三方软件仓库更新(提升apt体验)
安装时间较长的软件包
# later_task（apt-listchanges 等）必须在 Docker 等全部装完之后再装，见文件末尾。

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
    if [ "$SET_DOCKER_PURGE_REINSTALL" -eq 1 ]; then
        prompt -w "SET_DOCKER_PURGE_REINSTALL=1：将清除 Docker 数据（/var/lib/docker、/var/lib/containerd）后重装"
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do doApt remove $pkg; done
        # 彻底清除Docker
        for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras; do doApt purge $pkg; done
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd
        sudo rm -f /etc/apt/sources.list.d/docker.list
        sudo rm -f /etc/apt/keyrings/docker.asc /etc/apt/keyrings/docker.gpg
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
        prompt -x "将用户 $CURRENT_USER 加入 docker 组（免 sudo 跑 docker）"
        sudo groupadd -f docker
        sudo usermod -aG docker "$CURRENT_USER"
        prompt -m "docker 组已写入账号。当前会话不会立刻生效，请部署结束后重新登录。不要在脚本里 newgrp（会开新 shell，卡住后续步骤）。"
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

#### 禁用第三方仓库更新：不在检查点一白名单里的 sources.list.d 文件都挪走
if [ "$SET_DISABLE_THIRD_PARTY_REPO" -eq 1 ]; then
    prompt -x "禁用第三方软件仓库更新（保留检查点一记录的源）"
    deploy_apt_disable_third_party
fi

# 稍后安装黑名单：必须在本文件所有其它 apt 之后（否则 listchanges 会打断 Docker 等）
if [ "$SET_APT_INSTALL" -eq 1 ]; then
	if [ ${#later_task[@]} -eq 0 ]; then
		prompt -m "稍后安装列表为空，跳过。"
	else
		num=1
		for var in "${later_task[@]}"; do
			prompt -m "正在安装稍后列表第 $num 个软件包: $var（可交互）"
			doApt install "$var"
			num=$((num + 1))
		done
	fi
fi

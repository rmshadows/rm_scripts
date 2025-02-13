#!/bin/bash
# 安装配置 NVM
# 来源: https://github.com/nvm-sh/nvm
SET_INSTALL_NVM=1

if [ "$SET_INSTALL_NVM" -eq 1 ]; then
    # 安装 NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    # 或者使用 wget
    # wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    # 确保 NVM 被正确安装，重新加载配置文件
    source ~/.bashrc    # 如果使用 bash, 如果使用其他 shell 则修改为相应文件如 ~/.zshrc
    # 检查 NVM 是否成功安装
    if command -v nvm &> /dev/null; then
        echo "NVM 安装成功!"
    else
        echo "NVM 安装失败，请检查脚本执行日志。"
        exit 1
    fi

    # 如果 SET_NVM_INSTALL_NODEJS_LTS 为 1，则安装最新的 LTS 版本
    if [ "$SET_NVM_INSTALL_NODEJS_LTS" -eq 1 ]; then
        nvm install --lts
        nvm use --lts
        echo "已安装并使用最新的 LTS 版本 Node.js"
    fi

    # 如果 SET_NVM_INSTALL_NODEJS_LTS 为 0，则不安装 LTS，直接安装指定版本（如果有）
    if [ "$SET_NVM_INSTALL_NODEJS_LTS" -eq 0 ] && [ -n "$SET_NVM_INSTALL_NODEJS_VERSION" ]; then
        nvm install "$SET_NVM_INSTALL_NODEJS_VERSION"
        nvm use "$SET_NVM_INSTALL_NODEJS_VERSION"
        echo "已安装并使用指定版本的 Node.js: $SET_NVM_INSTALL_NODEJS_VERSION"
    fi
fi


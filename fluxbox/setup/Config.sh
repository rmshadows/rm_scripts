#!/bin/bash
:<<!说明
Fluxbox 部署配置
修改后运行: ./setup/deploy.sh
!说明

# 部署目标目录（空则使用 ~/.fluxbox）
SET_TARGET_DIR=""

# 部署前是否备份现有 ~/.fluxbox（带时间戳目录）
SET_BACKUP_BEFORE_DEPLOY=1

# 是否安装 apt 依赖（调用仓库根目录 apt-install.sh，需要 sudo）
SET_INSTALL_APT_DEPS=0

# 部署后初始化 default.theme 符号链接
SET_INIT_DEFAULT_THEME=1

# 部署后为 scripts 下 .sh 添加可执行权限
SET_CHMOD_SCRIPTS=1

# 是否部署 GTK 主题配置到用户目录 ~/.gtkrc-2.0
SET_DEPLOY_GTKRC=0

# 是否写入 ~/.fluxbox/config/sync.repo.path（供菜单内 Sync 工具使用）
SET_WRITE_SYNC_REPO_PATH=1

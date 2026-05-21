#!/bin/bash
#     从第三方 APT 仓库中自动查找并下载指定软件包（如 zerotier）的最新 .deb 安装文件。
# 适用于需要手动下载安装 .deb 文件而不是使用 apt 命令安装的情况，例如在离线安装或自定义仓库环境中。
# 🧾 脚本介绍
# 该脚本自动执行以下操作：
#    定义第三方仓库基础地址和要下载的软件包名。
#    从指定仓库路径下查找 .deb 文件链接（通常是软件包的安装文件）。
#    解析出最新的 .deb 文件名。
#   拼接成完整的下载链接并使用 wget 下载到本地。
#    下载完成后输出提示。

# 第三方 APT 仓库的基础 URL
BASE_URL="http://example.com/apt/ubuntu"

# 要下载的软件包名称
PACKAGE_NAME="zerotier"

# 从仓库的 pool 路径中获取最新的 .deb 文件名
# 拼接路径为：.../pool/main/z/zerotier/
# 使用 wget 下载页面内容，并用 grep 提取第一个 .deb 链接
DEB_URL=$(wget -qO- "$BASE_URL/pool/main/${PACKAGE_NAME:0:1}/$PACKAGE_NAME/" | grep -oP 'href="\K[^"]+.deb' | head -n 1)

# 如果未找到 .deb 文件，则退出
if [ -z "$DEB_URL" ]; then
    echo "未找到 $PACKAGE_NAME 的 .deb 包。"
    exit 1
fi

# 拼接完整的 .deb 下载链接
FULL_DEB_URL="$BASE_URL/pool/main/${PACKAGE_NAME:0:1}/$PACKAGE_NAME/$DEB_URL"

# 下载该 .deb 包到当前目录，并命名为 zerotier.deb
wget "$FULL_DEB_URL" -O "$PACKAGE_NAME.deb"

# 下载完成提示
echo "下载完成：$PACKAGE_NAME.deb"


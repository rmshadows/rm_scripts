#!/bin/bash
# 用法：./download_deb_with_deps.sh <包名> <保存目录>
# ---------------------------------------------------------------------------
# 名称：download_deb_with_deps.sh
# 作用：下载指定 APT 包及其依赖的所有 .deb 文件，便于离线安装
#
# 用法：
#   ./download_deb_with_deps.sh <包名> <保存目录>
#
# 参数说明：
#   <包名>      需要下载的主包名（如 curl、htop 等）
#   <保存目录>  用于保存下载的 .deb 文件及自动生成的安装脚本
#
# 脚本功能：
#   1. 使用 apt-rdepends 工具获取指定包的所有依赖项（递归解析）
#   2. 使用 apt download 下载每一个包的 .deb 文件
#   3. 自动生成一个 install_all.sh 安装脚本，用于目标离线系统安装
#      - 安装脚本会检查包是否已安装且版本一致，若是则跳过安装
#      - 所有操作记录到 install_log.txt 日志文件
#      - 安装结束后自动执行 apt-get install -f 修复依赖
#
# 注意事项：
#   - 需要在联网环境中运行此脚本以完成依赖分析和下载
#   - 建议提前运行 `sudo apt-get update` 确保获取最新依赖关系
#   - install_all.sh 可拷贝至其他机器在离线环境中执行
#
# 示例：
#   ./download_deb_with_deps.sh curl ./offline_curl
#
# 更新时间：2025-06-02
# ---------------------------------------------------------------------------
set -e

PKG="$1"
DEST="$2"

if [[ -z "$PKG" || -z "$DEST" ]]; then
    echo "用法: $0 <包名> <保存目录>"
    exit 1
fi

mkdir -p "$DEST"
cd "$DEST"

echo "[+] 安装依赖工具 apt-rdepends（如未安装）"
if ! command -v apt-rdepends &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y apt-rdepends
fi

echo "[+] 获取 $PKG 的所有依赖列表..."
DEPS=$(apt-rdepends "$PKG" 2>/dev/null | grep -v "^ " | grep -v "^PreDepends:" | grep -v "^Depends:" | sort -u)

echo "[+] 将下载以下包:"
echo "$DEPS"

echo "[+] 开始逐个下载 .deb 包..."

for pkg in $DEPS; do
    echo "  → 正在下载：$pkg"
    apt download "$pkg" 2>/dev/null || echo "    [!] 下载失败：$pkg"
done

echo "[+] 所有包已下载到目录：$DEST"

#echo "[+] 生成 install_all.sh 安装脚本..."
#cat > install_all.sh <<EOF
##!/bin/bash
#echo "[*] 正在安装所有 .deb 包..."
#sudo dpkg -i *.deb
#sudo apt-get install -f -y
#EOF

echo "[+] 生成 install_all.sh 安装脚本..."
cat > install_all.sh <<'EOF'
#!/bin/bash
echo "[*] 正在安装所有 .deb 包..."

LOG="install_log.txt"
> "\$LOG"

for deb in *.deb; do
    # 提取包名和版本
    PKG_NAME=\$(dpkg-deb -f "\$deb" Package)
    PKG_VER=\$(dpkg-deb -f "\$deb" Version)

    if dpkg -s "\$PKG_NAME" &>/dev/null; then
        INSTALLED_VER=\$(dpkg-query -W -f='${Version}' "\$PKG_NAME")
        if [[ "\$INSTALLED_VER" == "\$PKG_VER" ]]; then
            echo "[=] 跳过已安装的包：\$PKG_NAME (\$PKG_VER)" | tee -a "\$LOG"
            continue
        fi
    fi

    echo "[+] 安装包：\$PKG_NAME (\$PKG_VER)" | tee -a "\$LOG"
    sudo dpkg -i "\$deb" >>"\$LOG" 2>&1
done

echo "[*] 修复依赖..."
sudo apt-get install -f -y | tee -a "\$LOG"

echo "[✓] 安装完成，日志保存在 \$LOG"
EOF

chmod +x install_all.sh

echo "[✓] 离线包和安装脚本已准备好，拷贝目录到目标机器后运行 ./install_all.sh"


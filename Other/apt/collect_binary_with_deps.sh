#!/bin/bash
# 用法: ./collect_binary_with_deps.sh /path/to/binary [output-dir]
# ------------------------------------------------------------------------------
# 名称：collect_binary_with_deps.sh
# 功能：收集可执行文件及其依赖库，打包成便于迁移和离线运行的目录
#
# 用法：
#   ./collect_binary_with_deps.sh /path/to/binary [output-dir]
#
# 参数说明：
#   /path/to/binary   要打包的主程序路径（如 /usr/bin/ffmpeg）
#   [output-dir]      可选，输出目录名称（默认为 <binary>_bundle）
#
# 脚本功能：
#   - 拷贝目标可执行文件到 output-dir/bin/
#   - 分析其动态链接库依赖，拷贝到 output-dir/lib/
#   - 自动生成 run.sh 启动脚本，设置 LD_LIBRARY_PATH 后运行主程序
#
# 运行后目录结构如下：
#   output-dir/
#     ├── bin/        # 主程序
#     ├── lib/        # 所有依赖库
#     └── run.sh      # 一键启动脚本
#
# 示例：
#   ./collect_binary_with_deps.sh /usr/bin/dislocker
#   cd dislocker_bundle && ./run.sh -V
#
# 适用于打包工具或命令行程序，实现跨环境、离线运行。
# ------------------------------------------------------------------------------


set -e

if [ -z "$1" ]; then
    echo "用法: $0 /path/to/binary [output-dir]"
    exit 1
fi

BINARY="$1"
BINARY_NAME=$(basename "$BINARY")
OUTDIR="${2:-${BINARY_NAME}_bundle}"

echo "[+] 目标可执行文件: $BINARY"
echo "[+] 输出目录: $OUTDIR"

mkdir -p "$OUTDIR/bin"
mkdir -p "$OUTDIR/lib"

# 拷贝主可执行文件
cp "$BINARY" "$OUTDIR/bin/"

echo "[+] 分析依赖库..."
ldd "$BINARY" | awk '/=> \// { print $(NF-1) }' | sort -u | while read -r lib; do
    if [ -f "$lib" ]; then
        echo "    拷贝库: $lib"
        cp -u "$lib" "$OUTDIR/lib/"
    else
        echo "    ⚠️ 找不到库文件: $lib"
    fi
done

# 可选：生成一键启动脚本
cat > "$OUTDIR/run.sh" <<EOF
#!/bin/bash
# 获取脚本所在目录的绝对路径，存入变量 SCRIPT_DIR。
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
#  设置动态链接库搜索路径，把脚本目录下的 lib/ 加入 LD_LIBRARY_PATH。
export LD_LIBRARY_PATH="\$SCRIPT_DIR/lib:\$LD_LIBRARY_PATH"
# 👉 执行你打包好的程序 dislocker，并将用户传入的所有参数（\$@）原样传递过去。
exec "\$SCRIPT_DIR/bin/$BINARY_NAME" "\$@"
EOF

chmod +x "$OUTDIR/run.sh"

echo -e "\n[+] ✅ 打包完成: $OUTDIR"
echo "    用法: cd $OUTDIR && ./run.sh [参数]"


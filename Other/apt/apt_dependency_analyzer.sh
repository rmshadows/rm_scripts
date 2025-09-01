#!/bin/bash

# 用法: ./apt_conflict_analyzer_v2.sh jitsi-meet
if [ -z "$1" ]; then
    echo "用法: $0 <软件包名>"
    exit 1
fi

PACKAGE="$1"
TMP_LOG="/tmp/apt_conflict_log.txt"

echo "📦 正在模拟安装并分析冲突: $PACKAGE"
echo

# 强制使用英文环境，以便匹配
LANG=C sudo apt-get install --simulate -o Debug::pkgProblemResolver=true "$PACKAGE" > "$TMP_LOG" 2>&1

# 输出原始日志头几行便于排查
echo "🧾 [原始日志前几行]"
head -n 15 "$TMP_LOG"
echo

# 提取失败依赖信息
echo "🔍 [1] 检测到以下冲突或无法满足的依赖："
grep -E "but.*not going to be installed|but it is not installable|Depends:|Conflicts with|Breaks" "$TMP_LOG" | sed 's/^\s*//' | uniq
echo

# 提取“哪些依赖没有安装”
echo "🧩 [2] 下列软件包依赖未满足或版本冲突："
grep -oP '(?<=Depends: ).+?(?=,|\))' "$TMP_LOG" | sort | uniq
echo

# 一级依赖链
echo "🧱 [3] 软件包依赖链（一级）如下："
apt-cache depends "$PACKAGE" | grep -E "Depends|Recommends" | sed 's/.*ends:\s*//g'
echo

# 可用版本信息
echo "📋 [4] 依赖包的可用版本与状态："
while read -r dep; do
    [[ -n "$dep" ]] && apt-cache policy "$dep" | head -n 5
done <<< "$(apt-cache depends "$PACKAGE" | grep -E "Depends|Recommends" | awk '{print $2}' | sort | uniq)"

echo
echo "✅ 完成分析。你可以查看详细日志文件：$TMP_LOG"


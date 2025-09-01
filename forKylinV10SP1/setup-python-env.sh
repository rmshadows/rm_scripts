#!/bin/bash
# Python 环境配置脚本 - pip + Tkinter + 清华镜像

echo "=============================="
echo "🔧 Python 环境配置脚本"
echo "=============================="

# 1. 检查 python 是否存在
if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ 未检测到 Python3，请先安装："
    echo "    sudo apt install python3"
    exit 1
fi
echo "✅ Python3 已安装：$(python3 --version)"

# 2. 检查 pip 是否存在
if ! command -v pip3 >/dev/null 2>&1; then
    echo "❌ 未检测到 pip，正在安装..."
    sudo apt update
    sudo apt install -y python3-pip
else
    echo "✅ pip 已安装：$(pip3 --version)"
fi

# 3. 检查 Tkinter
if python3 -c "import tkinter" >/dev/null 2>&1; then
    echo "✅ Tkinter 已安装"
else
    echo "❌ Tkinter 未安装，正在安装..."
    sudo apt install -y python3-tk
fi

# 4. 用清华镜像升级 pip
echo "🚀 使用清华镜像升级 pip..."
python3 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip

# 5. 设置 pip 全局清华镜像源
echo "🔧 设置 pip 全局镜像源为清华大学..."
pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 6. 显示 pip 配置
echo "📋 当前 pip 配置："
pip3 config list

echo "✅ Python 环境配置完成"

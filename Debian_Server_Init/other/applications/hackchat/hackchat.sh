#!/bin/bash
## 需要有人职守，需要sudo
# 加载全局变量
source "../GlobalVariables.sh"
# 加载全局函数
source "../Lib.sh"
source "../ServiceInit.sh"

#### CONF
# 服务名
SRV_NAME=hackchat
# 指定运行端口
RUN_PORT=3000
# 反向代理的端口
REVERSE_PROXY_URL=/hc/

# 是否配置中文首页 Preset=0
CN_INDEX=0

SET_DIR=$(pwd)
# 返回之前的目录
# cd "$SET_DIR"

CN_INDEX_CONFIG="var frontpage = [\n	\"                            _           _         _       _   \",\n	\"                           | |_ ___ ___| |_   ___| |_ ___| |_ \",\n	\"                           |   |_ ||  _| '_| |  _|   |_ ||  _|\",\n	\"                           |_|_|__/|___|_,_|.|___|_|_|__/|_|  \",\n	\"\",\n	\"\",\n	\"欢迎使用hack.chat，这是一个迷你的、无干扰的加密聊天应用程序。\",\n	\"频道是通过url创建、加入和共享的，通过更改问号后的文本来创建自己的频道(请使用英文字母)。\",\n	\"如果您希望频道名称(房间名)为：‘ hello ’,请在浏览器地址栏输入： https://网址/?hello\",\n	\"这里没有公开频道列表，因此你可以使用秘密的频道名称(也就是别人都猜不到的房间名)进行私人讨论。在这里，聊天记录不会被记录，聊天信息传输也是加密的(除非你不是用的https访问本站，或者你的电脑遭到攻击)。\",\n	\"下面是预设的房间：休息室、元数据、数学、物理、化学、科技、编程、游戏、香蕉\",\n	\"\",\n	\"\",\n	\"?lounge ?meta\",\n	\"?math ?physics ?chemistry\",\n	\"?technology ?programming\",\n	\"?games ?banana\",\n	\"\",\n	\"\",\n	\"\",\n	\"\",\n	\"# 这里为你随机生成了一个聊天室（请点击链接进入房间）: ?\" + Math.random().toString(36).substr(2, 8),\n	\"\",\n	\"\",\n	\"\",\n	\"\",\n	\"语法支持(支持部分Markdown语法)：\",\n	\"空格缩进(两个或四个空格)、Tab键是保留字符，因此可以逐字粘贴源代码(回车请用Shift+Enter)。比如：\",\n	\"\`\`\`	# 这是代码\`\`\`\",\n	\"\`\`\`	#!/bin/bash\`\`\`\",\n	\"\`\`\`	echo hello\`\`\`\",\n	\"支持LaTeX语法(数学公式)，单行显示请用一个美元符号包围数学公式，多行显示(展示公式)请用两个美元符号包围。\",\n	\"单行：\`\`\`$\\\\\\\zeta(2) = \\\\\\\pi^2/6$\`\`\`  $\\\\\\\zeta(2) = \\\\\\\pi^2/6$\",\n	\"多行：\`\`\`\$\$\\\\\\\int_0^1 \\\\\\\int_0^1 \\\\\\\\frac{1}{1-xy} dx dy = \\\\\\\frac{\\\\\\\pi^2}{6}\$\$\`\`\`  \$\$\\\\\\\int_0^1 \\\\\\\int_0^1 \\\\\\\frac{1}{1-xy} dx dy = \\\\\\\frac{\\\\\\\pi^2}{6}\$\$\",\n	\"对于语法突出显示，将代码包装为：\`\`\`<language> <the code>\`\`\`其中<language>是任何已知的编程语言。\",\n	\"\",\n	\"当前的Github代码仓库: https://github.com/hack-chat\",\n	\"旧版GitHub代码仓库: https://github.com/AndrewBelt/hack.chat\",\n	\"\",\n\n	\"机器人，Android客户端，桌面客户端，浏览器扩展，Docker映像，编程库，服务器模块等:\",\n	\"https://github.com/hack-chat/3rd-party-software-list\",\n	\"根据WTFPL和MIT开源许可证发布的服务器和Web客户端。\",\n	\"hack.chat服务器不会保留任何聊天记录。\",\n	\"\",\n	\"\",\n	\"Welcome to hack.chat, a minimal, distraction-free chat application.\",\n	\"Channels are created, joined and shared with the url, create your own channel by changing the text after the question mark.\",\n	\"If you wanted your channel name to be 'your-channel': https://hack.chat/?your-channel\",\n	\"There are no channel lists, so a secret channel name can be used for private discussions.\",\n	\"\",\n	\"\",\n	\"Here are some pre-made channels you can join:\",\n	\"?lounge ?meta\",\n	\"?math ?physics ?chemistry\",\n	\"?technology ?programming\",\n	\"?games ?banana\",\n	\"And here's a random one generated just for you: ?\" + Math.random().toString(36).substr(2, 8),\n	\"\",\n	\"\",\n	\"Formatting:\",\n	\"Whitespace is preserved, so source code can be pasted verbatim.\",\n	\"Surround LaTeX with a dollar sign for inline style $\\\\\\\zeta(2) = \\\\\\\pi^2/6$, and two dollars for display. \$\$\\\\\\\int_0^1 \\\\\\\int_0^1 \\\\\\\frac{1}{1-xy} dx dy = \\\\\\\frac{\\\\\\\pi^2}{6}\$\$\",\n	\"For syntax highlight, wrap the code like: \`\`\`<language> <the code>\`\`\` where <language> is any known programming language.\",\n	\"\",\n	\"Current Github: https://github.com/hack-chat\",\n	\"Legacy GitHub: https://github.com/AndrewBelt/hack.chat\",\n	\"\",\n	\"Bots, Android clients, desktop clients, browser extensions, docker images, programming libraries, server modules and more:\",\n	\"https://github.com/hack-chat/3rd-party-software-list\",\n	\"\",\n	\"Server and web client released under the WTFPL and MIT open source license.\",\n	\"No message history is retained on the hack.chat server.\"\n].join(\"\\\\n\");"

: <<CN
这个注释是上面的
"var frontpage = [
	\"                            _           _         _       _   \",
	\"                           | |_ ___ ___| |_   ___| |_ ___| |_ \",
	\"                           |   |_ ||  _| '_| |  _|   |_ ||  _|\",
	\"                           |_|_|__/|___|_,_|.|___|_|_|__/|_|  \",
	\"\",
	\"\",
	\"欢迎使用hack.chat，这是一个迷你的、无干扰的加密聊天应用程序。\",
	\"频道是通过url创建、加入和共享的，通过更改问号后的文本来创建自己的频道(请使用英文字母)。\",
	\"如果您希望频道名称(房间名)为：‘ hello ’,请在浏览器地址栏输入： https://网址/?hello\",
	\"这里没有公开频道列表，因此你可以使用秘密的频道名称(也就是别人都猜不到的房间名)进行私人讨论。在这里，聊天记录不会被记录，聊天信息传输也是加密的(除非你不是用的https访问本站，或者你的电脑遭到攻击)。\",
	\"下面是预设的房间：休息室、元数据、数学、物理、化学、科技、编程、游戏、香蕉\",
	\"\",
	\"\",
	\"?lounge ?meta\",
	\"?math ?physics ?chemistry\",
	\"?technology ?programming\",
	\"?games ?banana\",
	\"\",
	\"\",
	\"\",
	\"\",
	\"# 这里为你随机生成了一个聊天室（请点击链接进入房间）: ?\" + Math.random().toString(36).substr(2, 8),
	\"\",
	\"\",
	\"\",
	\"\",
	\"语法支持(支持部分Markdown语法)：\",
	\"空格缩进(两个或四个空格)、Tab键是保留字符，因此可以逐字粘贴源代码(回车请用Shift+Enter)。比如：\",
	\"\`\`\`	# 这是代码\`\`\`\",
	\"\`\`\`	#!/bin/bash\`\`\`\",
	\"\`\`\`	echo hello\`\`\`\",
	\"支持LaTeX语法(数学公式)，单行显示请用一个美元符号包围数学公式，多行显示(展示公式)请用两个美元符号包围。\",
	\"单行：\`\`\`$\\\\\\\zeta(2) = \\\\\\\pi^2/6$\`\`\`  $\\\\\\\zeta(2) = \\\\\\\pi^2/6$\",
	\"多行：\`\`\`\$\$\\\\\\\int_0^1 \\\\\\\int_0^1 \\\\\\\frac{1}{1-xy} dx dy = \\\\\\\frac{\\\\\\\pi^2}{6}\$\$\`\`\`  \$\$\\\\\\\int_0^1 \\\\\\\int_0^1 \\\\\\\frac{1}{1-xy} dx dy = \\\\\\\frac{\\\\\\\pi^2}{6}\$\$\",
	\"对于语法突出显示，将代码包装为：\`\`\`<language> <the code>\`\`\`其中<language>是任何已知的编程语言。\",
	\"\",
	\"当前的Github代码仓库: https://github.com/hack-chat\",
	\"旧版GitHub代码仓库: https://github.com/AndrewBelt/hack.chat\",
	\"\",

	\"机器人，Android客户端，桌面客户端，浏览器扩展，Docker映像，编程库，服务器模块等:\",
	\"https://github.com/hack-chat/3rd-party-software-list\",
	\"根据WTFPL和MIT开源许可证发布的服务器和Web客户端。\",
	\"hack.chat服务器不会保留任何聊天记录。\",
	\"\",
	\"\",
	\"Welcome to hack.chat, a minimal, distraction-free chat application.\",
	\"Channels are created, joined and shared with the url, create your own channel by changing the text after the question mark.\",
	\"If you wanted your channel name to be 'your-channel': https://hack.chat/?your-channel\",
	\"There are no channel lists, so a secret channel name can be used for private discussions.\",
	\"\",
	\"\",
	\"Here are some pre-made channels you can join:\",
	\"?lounge ?meta\",
	\"?math ?physics ?chemistry\",
	\"?technology ?programming\",
	\"?games ?banana\",
	\"And here's a random one generated just for you: ?\" + Math.random().toString(36).substr(2, 8),
	\"\",
	\"\",
	\"Formatting:\",
	\"Whitespace is preserved, so source code can be pasted verbatim.\",
	\"Surround LaTeX with a dollar sign for inline style $\\\\\\\zeta(2) = \\\\\\\pi^2/6$, and two dollars for display. \$\$\\\\\\\int_0^1 \\\\\\\int_0^1 \\\\\\\frac{1}{1-xy} dx dy = \\\\\\\frac{\\\\\\\pi^2}{6}\$\$\",
	\"For syntax highlight, wrap the code like: \`\`\`<language> <the code>\`\`\` where <language> is any known programming language.\",
	\"\",
	\"Current Github: https://github.com/hack-chat\",
	\"Legacy GitHub: https://github.com/AndrewBelt/hack.chat\",
	\"\",
	\"Bots, Android clients, desktop clients, browser extensions, docker images, programming libraries, server modules and more:\",
	\"https://github.com/hack-chat/3rd-party-software-list\",
	\"\",
	\"Server and web client released under the WTFPL and MIT open source license.\",
	\"No message history is retained on the hack.chat server.\"
].join(\"\n\");"
CN

#### 正文
### 准备工作
# 检查包是否已安装
t_pkg="git"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    sudo apt update && sudo apt install $t_pkg                       # 更新包列表并安装
fi

t_pkg="npm"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    sudo apt update && sudo apt install $t_pkg                       # 更新包列表并安装
fi

t_pkg="nodejs"
if ! command -v node &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    sudo apt update && sudo apt install $t_pkg                       # 更新包列表并安装
fi

t_pkg="gawk"
if ! command -v $t_pkg &>/dev/null; then
    echo -e "\033[31m$t_pkg not found! Install $t_pkg first!\033[0m" # 输出红色提示
    sudo apt update && sudo apt install $t_pkg                       # 更新包列表并安装
fi

### 安装软件
if ! [ -d $HOME/Applications ]; then
    mkdir $HOME/Applications
fi

prompt -x "Install hackchat..."
cd $HOME/Applications
git clone https://github.com/hack-chat/main.git hackchat

if ! [ -d $HOME/Applications/hackchat ]; then
    prompt -e "Git seems failed..."
    exit 1
fi

cd -
cd "$HOME/Applications/hackchat"
npm install
cd -

### 服务生成
# 创建应用专门的服务文件夹
if ! [ -d "$HOME/Services/$SRV_NAME" ]; then
    prompt -x "Mkdir $HOME/Services/$SRV_NAME..."
    sudo mkdir "$HOME/Services/$SRV_NAME"
fi
# 生成服务
prompt -x "Making Service..."
replace_placeholders_with_values srv.service.src
sudo mv srv.service /home/$USER/Services/$SRV_NAME.service
# 安装服务
prompt -x "Install service..."
cd $HOME/Services/
sudo $HOME/Services/Install_Servces.sh
# 拷贝启动和停止的脚本
cd "$SET_DIR"
prompt -x "Make start and stop script..."
# Start and stop script
sudo cp start.sh /home/$USER/Services/$SRV_NAME/start_"$SRV_NAME".sh
sudo cp stop.sh /home/$USER/Services/$SRV_NAME/stop_"$SRV_NAME".sh
sudo chmod +x /home/$USER/Services/$SRV_NAME/*.sh

# 修改端口号
if [ "$RUN_PORT" -ne 3000 ]; then
    prompt -x "Change web page port at $RUN_PORT"
    cd $HOME/Applications/hackchat
    # pwd
    # pm2.config.js
    sed -i s/client\ -p\ 3000\ -o/client\ -p\ $RUN_PORT\ -o/g pm2.config.js
    cd -
fi
# 修改主页
if [ "$CN_INDEX" -eq 1 ]; then
    cd $HOME/Applications/hackchat
    ss="var frontpage"
    se="function \$(query)"
    # 获取ss行号
    idxs=$(cat client/client.js | grep -n "$ss" | gawk '{print $1}' FS=":")
    # 找到的Index
    idxsl=($idxs)
    idxslen=${#idxsl[@]}
    if [ "$idxslen" -eq 1 ]; then
        prompt -i "Found start : $idxs"
    elif [ "$idxslen" -eq 0 ]; then
        echo -e "1:Configure no found at client/client.js Check manually!"
        exit 1
    else
        echo -e "1:Find duplicate user setting in client/client.js! Check manually!"
        exit 1
    fi
    # 获取se行号
    idxe=$(cat client/client.js | grep -n "$se" | gawk '{print $1}' FS=":")
    # 找到的Index
    idxel=($idxe)
    idxelen=${#idxel[@]}
    if [ "$idxelen" -eq 1 ]; then
        prompt -i "Found start : $idxe"
    elif [ "$idxelen" -eq 0 ]; then
        echo -e "2:Configure no found at client/client.js Check manually!"
        exit 1
    else
        echo -e "2:Find duplicate user setting in client/client.js! Check manually!"
        exit 1
    fi
    prompt -x "Del client/client.js front page setting...."
    for ((i = $idxs; i < $((idxe - 1)); i++)); do
        sed -i "$idxs d" client/client.js
    done
    prompt -x "Add client/client.js front page CN setting...."
    sed -i "$idxs i $CN_INDEX_CONFIG" client/client.js
fi

### 反向代理配置
cd "$SET_DIR"
prompt -i "Check manully and setting up reverse proxy by yourself."
replace_placeholders_with_values reverse_proxy.txt.src
prompt -i "========================================================"
cat reverse_proxy.txt
prompt -i "========================================================"

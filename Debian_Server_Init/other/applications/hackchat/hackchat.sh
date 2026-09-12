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
RUN_PORT=2001
# Nginx 子路径（挂在主站域名下，不用独立端口）
REVERSE_PROXY_PATH="/hc/"
# wss 路径（主站上的 location）
WS_PATH="/hc-wss"

# 应用访问域名：当前未在安装流程中直接使用，仅作为域名占位记录。
# hackchat 通过子路径 /hc/ 挂载在主站下，实际访问域名为部署主站的域名。
YOUR_DOMAIN="example.com"

# 是否配置中文首页 Preset=0
CN_INDEX=0
# 固定的上游版本（commit SHA，可复现部署）。上游无 tag/release，只能固定 SHA。
# 升级方法：git ls-remote https://github.com/hack-chat/main.git 取最新 SHA 替换；
# 或直接设为 "master" 每次运行自动追最新（可能因上游变更而失败）。
HACKCHAT_REF="b9ea8651488284005fb9368e336eba1a6edfcf11"

# 指定 client.js 文件路径
CLIENT_JS_PATH="client/client.js"

# 保存当前目录（运行脚本时应在 hackchat/ 下）
SET_DIR=$(pwd)

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
	\"如果您希望频道名称(房间名)为：‘ hello ’,请在浏览器地址栏输入： https://$YOUR_DOMAIN/?hello\",
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
mkdir -p "$HOME/Applications"
cd "$HOME/Applications"
if [ ! -d hackchat/.git ]; then
    # 全新安装：clone 后切到固定版本
    prompt -x "Clone hackchat ($HACKCHAT_REF)..."
    rm -rf hackchat
    git clone https://github.com/hack-chat/main.git hackchat
    cd hackchat || { prompt -e "Git clone 或 cd 失败"; exit 1; }
    git checkout -q "$HACKCHAT_REF"
    HC_UPDATED=1
else
    cd hackchat
    # 已安装：解析目标 SHA（master 时拉取远端最新）
    cur_sha=$(git rev-parse HEAD)
    if [ "$HACKCHAT_REF" = "master" ]; then
        git fetch -q origin master
        want_sha=$(git rev-parse origin/master)
    else
        want_sha=$(git rev-parse -q --verify "${HACKCHAT_REF}^{commit}" 2>/dev/null) || {
            git fetch -q origin
            want_sha=$(git rev-parse -q --verify "${HACKCHAT_REF}^{commit}" 2>/dev/null)
        }
    fi
    if [ -z "$want_sha" ]; then
        prompt -e "无法解析 HACKCHAT_REF=$HACKCHAT_REF，请检查 SHA 是否正确"
        exit 1
    fi
    if [ "$cur_sha" = "$want_sha" ]; then
        prompt -i "[跳过] hackchat 版本已是目标版本 ${want_sha:0:12}"
        HC_UPDATED=0
    else
        prompt -x "更新 hackchat: ${cur_sha:0:12} -> ${want_sha:0:12}"
        # -f 丢弃脚本对 client.js / pm2 配置的本地修改（更新后会重新打补丁）
        # 未跟踪文件 session.key/salt.key/config.json 不受影响
        git checkout -qf "$want_sha"
        HC_UPDATED=1
    fi
fi

# 依赖：版本有更新，或关键包缺失/残缺时重装
# （npm 失败会留下残缺 node_modules，不能只看目录存在）
if [ "$HC_UPDATED" -eq 0 ] && [ -d node_modules/uwuify ] && [ -d node_modules/hackchat-server ]; then
    prompt -i "[跳过] npm 依赖已安装"
else
    rm -rf node_modules || true
    # uwuify@1.0.1 已从官方源下架(404)，官方源失败自动回退 npmmirror 镜像
    npm_ok=0
    for reg in "https://registry.npmjs.org" "https://registry.npmmirror.com"; do
        prompt -x "npm install --ignore-scripts (registry: $reg)"
        # --ignore-scripts 跳过交互式 postinstall（会要求输入管理员密码）
        if npm install --ignore-scripts --registry="$reg"; then
            npm_ok=1
            break
        fi
        prompt -w "registry $reg 安装失败 (exit=$?)，清理后尝试下一个源"
        rm -rf node_modules package-lock.json 2>/dev/null || true
        # lock 文件里锁定了官方源 tarball 地址，回退镜像时删掉让 npm 重新解析
        git checkout -q -- package-lock.json 2>/dev/null || rm -f package-lock.json 2>/dev/null || true
    done
    if [ "$npm_ok" -ne 1 ]; then
        prompt -e "npm install 在所有源上均失败，请检查网络后重跑本脚本（会自动重试）"
        exit 1
    fi
    prompt -s "npm 依赖安装完成"

    # 新版 postinstall(npm run config) 是交互式的，无人值守下直接生成所需文件：
    # main.mjs 启动强制要求 session.key / salt.key / config.json
    [ -f session.key ] || head -c 4096 /dev/urandom > session.key
    [ -f salt.key ] || head -c 4096 /dev/urandom > salt.key
    if [ ! -f config.json ]; then
        printf '{"adminTrip":"","globalMods":[],"publicChannels":[],"permissions":[]}' > config.json
        prompt -w "已生成默认 config.json（无管理员）。如需管理员权限，之后在应用目录运行 npm run config 交互式设置。"
    fi
fi

# 新版 pm2 配置文件为 pm2.config.cjs，兼容旧版 pm2.config.js
PM2_CONF=""
[ -f pm2.config.cjs ] && PM2_CONF=pm2.config.cjs
[ -z "$PM2_CONF" ] && [ -f pm2.config.js ] && PM2_CONF=pm2.config.js

# pm2 端口号：已设置则跳过
if [ "$RUN_PORT" -ne 3000 ]; then
    if [ -z "$PM2_CONF" ]; then
        prompt -w "未找到 pm2.config.cjs/js，跳过端口修改"
    elif grep -q "client -p $RUN_PORT -o" "$PM2_CONF"; then
        prompt -i "[跳过] pm2 端口已为 $RUN_PORT"
    else
        prompt -x "Change web page port at $RUN_PORT ($PM2_CONF)"
        sed -i "s/client -p 3000 -o/client -p $RUN_PORT -o/g" "$PM2_CONF"
    fi
fi

### 修改 client.js（幂等：检测是否已修改）
if [ ! -f "$CLIENT_JS_PATH" ]; then
    echo "文件 $CLIENT_JS_PATH 未找到，退出！"
    exit 1
fi

# wsPath: 必须指向 WS 反代路径（/hc-wss -> 6060），不是 Web 子路径 /hc/
# 目标值已存在（行首，无缩进）则跳过
if grep -q "^var wsPath = '$WS_PATH';" "$CLIENT_JS_PATH"; then
    prompt -i "[跳过] wsPath 已设置为 $WS_PATH"
else
    echo "正在修改 WebSocket 配置..."
    # 注释掉所有 var wsPath = 赋值行（允许行首有空格/制表符缩进）
    sed -i '/^[[:space:]]*var wsPath[[:space:]]*=/s|^|//|' "$CLIENT_JS_PATH"
    # 在文件首行插入目标 wsPath
    sed -i "1i var wsPath = '$WS_PATH';" "$CLIENT_JS_PATH"
    grep -n "wsPath" "$CLIENT_JS_PATH"
fi

### 服务生成（始终重跑，覆盖式）
# 生成文件放 /tmp 再 sudo 安装，避免 SET_DIR 或 Services 目录权限问题
sudo mkdir -p "$HOME/Services/$SRV_NAME"
cd "$SET_DIR"
prompt -x "Making Service..."
tmp_svc=$(mktemp)
sed -e "s|【\$SRV_NAME】|$SRV_NAME|g" -e "s|【\$USER】|$USER|g" srv.service.src > "$tmp_svc"
sudo cp "$tmp_svc" "$HOME/Services/$SRV_NAME.service"
rm -f "$tmp_svc"
prompt -x "Install service..."
cd "$HOME/Services/"
sudo "$HOME/Services/Install_Services.sh"
cd "$SET_DIR"
prompt -x "Make start and stop script..."
# 解析 node/npm 所在目录，写入 start.sh 的 PATH（systemd 环境 PATH 很精简，nvm 装的 node 尤其需要）
NODE_BIN="$(dirname "$(command -v node 2>/dev/null || echo /usr/bin)")"
tmp_start=$(mktemp)
sed -e "s|【\$RUN_PORT】|$RUN_PORT|g" -e "s|【\$NODE_BIN】|$NODE_BIN|g" start.sh > "$tmp_start"
sudo cp "$tmp_start" "$HOME/Services/$SRV_NAME/start_${SRV_NAME}.sh"
rm -f "$tmp_start"
sudo cp stop.sh "$HOME/Services/$SRV_NAME/stop_${SRV_NAME}.sh"
# 属主改回当前用户（sudo cp 会让文件属主变 root），确保 systemd 以 User= 身份能执行
sudo chown "$USER:$USER" "$HOME/Services/$SRV_NAME/"*.sh
sudo chmod 755 "$HOME/Services/$SRV_NAME/"*.sh

# 中文首页：已包含中文欢迎语则跳过
if [ "$CN_INDEX" -eq 1 ]; then
    cd "$HOME/Applications/hackchat"
    if grep -q "欢迎使用hack.chat" client/client.js; then
        prompt -i "[跳过] 中文首页已设置"
    else
        ss="var frontpage"
        se="function \$(query)"
        idxs=$(cat client/client.js | grep -n "$ss" | gawk '{print $1}' FS=":")
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
        idxe=$(cat client/client.js | grep -n "$se" | gawk '{print $1}' FS=":")
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
fi

### Nginx 子路径片段（始终重跑，覆盖式）
cd "$SET_DIR"
if [ -f setupNginxForHackchat.sh ]; then
    prompt -x "运行 setupNginxForHackchat.sh（写入 /etc/nginx/snippets/hackchat.conf，子路径 $REVERSE_PROXY_PATH，WS $WS_PATH）"
    export RUN_PORT REVERSE_PROXY_PATH WS_PATH
    export WS_PORT="${WS_PORT:-6060}"
    bash setupNginxForHackchat.sh
    prompt -i "启用：在主站 server { } 内加 include /etc/nginx/snippets/hackchat.conf; 然后 sudo nginx -t && sudo systemctl reload nginx"
    prompt -i "client.js wsPath 已自动设置为 $WS_PATH"
else
    prompt -w "未找到 setupNginxForHackchat.sh。"
fi

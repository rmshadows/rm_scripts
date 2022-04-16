CN_INDEX_CONFIG="
var frontpage = [
	\"                            _           _         _       _   \",
	\"                           | |_ ___ ___| |_   ___| |_ ___| |_ \",
	\"                           |   |_ ||  _| ' _| |  _|   |_ ||  _|\",
	\"                           |_|_|__/|___|_,_|.|___|_|_|__/|_|  \",
	\"\",
	\"\",
	\"欢迎使用hack.chat，这是一个迷你的、无干扰的加密聊天应用程序。\",
	\"频道是通过url创建、加入和共享的，通过更改问号后的文本来创建自己的频道(请使用英文字母)。\",
	\"如果您希望频道名称(房间名)为：‘ hello ’,请在浏览器地址栏输入： https://civiccccc.ltd/hc/?hello\",
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
	\"\`\`\`	\# 这是代码\`\`\`\",
	\"\`\`\`	\#\!/bin/bash\`\`\`\",
	\"\`\`\`	echo hello\`\`\`\",
	\"支持LaTeX语法(数学公式)，单行显示请用一个美元符号包围数学公式，多行显示(展示公式)请用两个美元符号包围。\",
	\"单行：\`\`\`$\"zeta(2) = \\\\pi^2/6$\`\`\`  $\\\\zeta(2) = \\\\pi^2/6$\",
	\"多行：\`\`\`\$\$\\\\int_0^1 \\\\int_0^1 \\\\frac{1}{1-xy} dx dy = \\\\frac{\\\\pi^2}{6}\$\$\`\`\`  \$\$\\\\int_0^1 \\\\int_0^1 \\\\frac{1}{1-xy} dx dy = \\\\frac{\\\\pi^2}{6}\$\$\",
	\"对于语法突出显示，将代码包装为：\`\`\`\<language\> \<the code\>\`\`\`其中<language>是任何已知的编程语言。\",
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
	\"Surround LaTeX with a dollar sign for inline style $\\\\zeta(2) = \\\\pi^2/6$, and two dollars for display. \$\$\\\\int_0^1 \\\\int_0^1 \\\\frac{1}{1-xy} dx dy = \\\\frac{\\\\pi^2}{6}\$\$\",
	\"For syntax highlight, wrap the code like: \`\`\`\<language\> \<the code\>\`\`\` where <language> is any known programming language.\",
	\"\",
	\"Current Github: https://github.com/hack-chat\",
	\"Legacy GitHub: https://github.com/AndrewBelt/hack.chat\",
	\"\",
	\"Bots, Android clients, desktop clients, browser extensions, docker images, programming libraries, server modules and more:\",
	\"https://github.com/hack-chat/3rd-party-software-list\",
	\"\",
	\"Server and web client released under the WTFPL and MIT open source license.\",
	\"No message history is retained on the hack.chat server.\"
].join(\"\n\");
"

CN_INDEX=1

if [ "$CN_INDEX" -eq 1 ];then
    ss="var frontpage"
    se="function \$(query)"
    # 获取ss行号
    idxs=`cat 1.txt | grep -n "$ss" | gawk '{print $1}' FS=":"`
    # echo $idx
    # 找到的Index
    idxsl=($idxs)
    idxslen=${#idxsl[@]}
    if [ $idxslen -eq 1 ];then
        echo $idxs
    elif [ $idxslen -eq 0 ];then
        echo -e "1:Configure no found at client/client.js Check manually!"
    else
        echo -e "1:Find duplicate user setting in client/client.js! Check manually!"
    fi
    # 获取se行号
    idxe=`cat 1.txt | grep -n "$se" | gawk '{print $1}' FS=":"`
    # 找到的Index
    idxel=($idxe)
    idxelen=${#idxel[@]}
    if [ $idxelen -eq 1 ];then
        echo $idxe
    elif [ $idxelen -eq 0 ];then
        echo -e "2:Configure no found at client/client.js Check manually!"
    else
        echo -e "2:Find duplicate user setting in client/client.js! Check manually!"
    fi
    for ((i=$ss;i<$se;i++));do
        sed -i "$i d" 1.txt
    done

fi


: <<检查点四
从APT仓库安装常用软件包
安装Python3
配置Python3源为清华大学镜像
配置Python3全局虚拟环境（Debian12中无法直接使用pip了）
安装配置Git(配置User Email)
安装配置SSH
安装配置npm(是否安装hexo)
检查点四

source "cfg.sh"

# 从APT仓库安装常用软件包
if [ "$SET_APT_INSTALL" -eq 1 ]; then
    # 准备安装的包名列表
    immediately_task=()
    # 脚本运行结束后要安装的包名
    later_task=()
    # 先判断要安装的列表
    if [ "$SET_APT_INSTALL_LIST_INDEX" -eq 0 ]; then
        # 自定义安装
        app_list=$APT_TO_INSTALL_INDEX_0
    elif [ "$SET_APT_INSTALL_LIST_INDEX" -eq 1 ]; then
        # 精简安装
        app_list=$APT_TO_INSTALL_INDEX_1
    elif [ "$SET_APT_INSTALL_LIST_INDEX" -eq 2 ]; then
        # 部分安装
        app_list=$APT_TO_INSTALL_INDEX_2
    elif [ "$SET_APT_INSTALL_LIST_INDEX" -eq 3 ]; then
        # 全部安装
        app_list=$APT_TO_INSTALL_INDEX_3
    fi
    # 首先，处理稍后要安装的软件包
    later_list=$SET_APT_TO_INSTALL_LATER
    later_list=$(echo $later_list | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d' | sed 's/\n/ /g')
    later_list=($later_list)
    later_len=${#later_list[@]}
    prompt -m "下列是脚本运行结束后要安装的软件包: "
    for ((i = 0; i < $later_len; i++)); do
        each=${later_list[$i]}
        index=$(expr index "$each" —)
        # 软件包名
        name=${later_list[$i]/$each/${each:0:($index - 1)}}
        # 添加到列表
        # later_task[$num]=${name}
        later_task[$i]=${name}
        prompt -i "$each"
    done
    sleep 8
    echo -e "\n\n\n"
    # 处理app_list列表
    # 把“- ”转为换行符 然后删除所有空格 最后删除第一行。echo $LST | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d'
    app_list=$(echo $app_list | sed 's/- /\n/g' | tr -d [:blank:] | sed '1d' | sed 's/\n/ /g')
    # 生成新的列表
    app_list=($app_list)
    # 接下来打印要安装的软件包列表, 显示的序号从0开始
    num=0
    app_len=${#app_list[@]}
    prompt -m "下列是即将安装的软件包: "
    for ((i = 0; i < $app_len; i++)); do
        # 显示序号
        echo -en "\e[1;35m$num)\e[0m"
        each=${app_list[$i]}
        index=$(expr index "$each" —)
        # 软件包名
        name=${app_list[$i]/$each/${each:0:($index - 1)}}
        immediately_task[$num]=${name}
        prompt -i "$each"
        num=$((num + 1))
    done
    sleep 10
    doApt install ${immediately_task[@]}
    if [ $? != 0 ]; then
        prompt -e "安装出错，列表中有仓库中没有的软件包。下面将进行逐个安装，按任意键继续。"
        sleep 2
        num=1
        for var in ${immediately_task[@]}; do
            prompt -m "正在安装第 $num 个软件包: $var。"
            doApt install $var
            num=$((num + 1))
        done
    fi
fi

# 安装Python3
if [ "$SET_PYTHON3_INSTALL" -eq 1 ]; then
    prompt -x "安装Python3和pip3"
    doApt install python3
    doApt install python3-pip
fi

# 配置Python3源为清华大学镜像
if [ "$SET_PYTHON3_MIRROR" -eq 1 ]; then
    prompt -x "更改pip源为清华大学镜像源"
    doApt install software-properties-common
    doApt install python3-software-properties
    doApt install python3-pip
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
fi

# 配置Python3全局虚拟环境（Debian 12中不能直接使用pip）
if [ "$SET_PYTHON3_VENV" -eq 1 ]; then
    prompt -x "配置Python3全局虚拟环境"
    doApt install python3-venv
    # pipx用于安装独立的全局python程序，如you-get
    doApt install pipx
    : <<!说明
请保证与zshrc中的配置对应
如： 注意：.zshrc中不能使用 CURRENT_USER变量!!!!
if [ -f "/home/$CURRENT_USER/.python_venv_activate" ];then
    source /home/$CURRENT_USER/.python_venv_activate
fi
或者
alias acpy='activatePythonVenv'
function activatePythonVenv(){
    # 如果存在Python虚拟环境激活文件
    if [ -f "/home/$CURRENT_USER/.python_venv_activate" ];then
        source /home/$CURRENT_USER/.python_venv_activate
    fi
}
!说明
    # 在这里修改Python虚拟环境参数
    venv_libs_dir="/home/$CURRENT_USER/.PythonVenv"
    act="/home/$CURRENT_USER/.python_venv_activate"
    # 首先检查有没有venv文件夹
    if [ -d "$venv_libs_dir" ]; then
        if ! [ -f "$venv_libs_dir/bin/activate" ]; then
            prompt -e "$venv_libs_dir 文件夹已存在，但似乎不是Python虚拟环境！"
        fi
        if ! [ -f "$venv_libs_dir/bin/activate.csh" ]; then
            prompt -e "$venv_libs_dir 文件夹已存在，但似乎不是Python虚拟环境！"
        fi
        prompt -s "$venv_libs_dir 文件夹已存在，进入Python虚拟环境....请运行 source $act "
        if ! [ -f "$act" ]; then
            prompt -s "正在生成 $act 文件...."
            echo "# Python 全局虚拟环境
source $venv_libs_dir/bin/activate" >$act
        else
            prompt -e "已经存在名为$act的文件....请自行验证文件正确性(source $venv_libs_dir/bin/activate)，退出!"
        fi
    else
        prompt -w "$venv_libs_dir文件夹不存在，开始创建Python虚拟环境！"
        prompt -x "新建虚拟环境文件夹 $venv_libs_dir"
        addFolder "$venv_libs_dir"
        python3 -m venv "$venv_libs_dir"
        prompt -s "进入Python虚拟环境....请运行 source $act "
        if ! [ -f "$act" ]; then
            prompt -s "正在生成 $act 文件...."
            echo "# Python 全局虚拟环境
source $venv_libs_dir/bin/activate" >$act
        else
            prompt -e "已经存在名为$act的文件....请自行验证文件正确性(source $venv_libs_dir/bin/activate)，退出!"
        fi
    fi
fi

# 安装配置Git(配置User Email)
if [ "$SET_INSTALL_GIT" -eq 1 ]; then
    prompt -x "安装Git"
    doApt install git
    if [ $? -eq 0 ]; then
        git config --global user.name "$SET_GIT_USER"
        git config --global user.email "$SET_GIT_EMAIL"
    else
        prompt -e "Git似乎安装失败了。"
        quitThis
    fi
fi

# 安装配置SSH
if [ "$SET_INSTALL_OPENSSH" -eq 1 ]; then
    sshdc="/etc/ssh/sshd_config"
    doApt install openssh-server
    if [ -f "$sshdc" ]; then
        check_file="$sshdc"
        backupFile "$check_file"
        check_var="^ClientAliveInterval"
        if sudo cat "$check_file" | grep "$check_var" >/dev/null; then
            echo -e "\e[1;34m请检查文件内容：
===============================================================\e[0m"
            sudo cat "$check_file"
            prompt -w "ClientAliveInterval 似乎已启用（如上所列），不做处理。"
        else
            echo "# server每隔60秒发送一次请求给client，然后client响应，从而保持连接 
ClientAliveInterval 60" | sudo tee -a "$sshdc"
        fi
        check_var="^ClientAliveCountMax"
        if sudo cat "$check_file" | grep "$check_var" >/dev/null; then
            echo -e "\e[1;34m请检查文件内容：
===============================================================\e[0m"
            sudo cat "$check_file"
            prompt -w "ClientAliveCountMax 似乎已启用（如上所列），不做处理。"
        else
            echo "# server发出请求后，client没有响应次数达到3，就自动断开连接，一般client会响应。
ClientAliveCountMax 3" | sudo tee -a "$sshdc"
        fi
        if [ "$SET_ENABLE_SSH" -eq 1 ]; then
            prompt -x "配置SSH服务开机自启"
            sudo systemctl enable ssh.service
        elif [ "$SET_ENABLE_SSH" -eq 0 ]; then
            prompt -x "禁用SSH服务开机自启"
            sudo systemctl disable ssh.service
        fi
    else
        prompt -e "请检查SSH是否成功安装！"
    fi
fi

# 安装配置npm(是否安装hexo)
if [ "$SET_INSTALL_NPM" -eq 1 ]; then
    doApt install npm
    if [ "$SET_INSTALL_CNPM" -eq 1 ]; then
        if ! [ -x "$(command -v cnpm)" ]; then
            prompt -x "安装CNPM"
            # https://r.npm.taobao.org已失效
            sudo npm install cnpm -g --registry=https://registry.npmmirror.com/
        fi
        if [ "$SET_INSTALL_HEXO" -eq 1 ]; then
            if ! [ -x "$(command -v hexo)" ]; then
                prompt -x "安装HEXO"
                sudo cnpm install -g hexo-cli
            fi
        fi
    fi
    if [ "$SET_INSTALL_HEXO" -eq 1 ]; then
        if ! [ -x "$(command -v hexo)" ]; then
            prompt -x "安装HEXO"
            sudo npm install -g hexo-cli
        fi
    fi
fi

if [ "$SET_INSTALL_NODEJS" -eq 1 ]; then
    doApt install nodejs
fi

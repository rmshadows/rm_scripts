: <<检查点四
从APT仓库安装常用软件包
安装Python3
配置Python3源为清华大学镜像
配置Python3全局虚拟环境（Debian12中无法直接使用pip了）
安装配置Apache2
配置PHP FPM
配置nginx
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
        app_list=$SEAPT_TO_INSTALL_INDEX_0
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
        later_task[$num]=${name}
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

# 配置Python3全局虚拟环境（Debian 12以后中不能直接使用pip）
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

# 安装配置Apache2
if [ "$SET_INSTALL_APACHE2" -eq 1 ]; then
    prompt -x "安装Apache2"
    doApt install apache2
    prompt -m "配置Apache2 共享目录为 /home/HTML"
    addFolder /home/HTML
    prompt -x "设置/home/HTML读写权限为755"
    sudo chmod 755 /home/HTML
    sudo chown "$CURRENT_USER" /home/HTML
    sudo chgrp "$CURRENT_USER" /home/HTML
    if [ $? -eq 0 ]; then
        backupFile /etc/apache2/apache2.conf
        prompt -x "修改Apache2配置文件中的共享目录为/home/HTML"
        sudo sed -i 's/\/var\/www\//\/home\/HTML\//g' /etc/apache2/apache2.conf
        sudo sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/home\/HTML/g' /etc/apache2/sites-available/000-default.conf
        if [ "$SET_ENABLE_APACHE2" -eq 0 ]; then
            prompt -x "禁用Apache2服务开机自启"
            sudo systemctl disable apache2.service
        elif [ "$SET_ENABLE_APACHE2" -eq 1 ]; then
            prompt -x "配置Apache2服务开机自启"
            sudo systemctl enable apache2.service
        fi
    else
        prompt -e "Apache2似乎安装失败了。"
        quitThis
    fi
fi

# 配置PHP FPM
if [ "$SET_INSTALL_PHP" -eq 1 ]; then
    prompt -x "安装Php和php-fpm"
    doApt install php
    doApt install php-fpm
    if [ $? -eq 0 ]; then
        # 获取版本号
        phpfpmVersion=$(sudo systemctl list-unit-files | grep "\-"fpm | grep ^php | sed 's/.fpm.*//' | sed 's/php//g')
        # 如果指定端口
        if [ "$SET_PHP_FPM_PORT" -ne 0 ]; then
            # 配置php fpm
            fromp=$(pwd)
            cd /etc/php/*/fpm/pool.d/
            phpconff=""www.conf""
            if [ -f "$phpconff" ]; then
                check_var="^listen = $SET_PHP_FPM_PORT"
                if cat "$phpconff" | grep "$check_var" >/dev/null; then
                    prompt -w "端口号似乎已经配置了!"
                else
                    # 存在配置文件就修改端口号 (在这里修改php fpm端口号)
                    prompt -x "修改php fpm端口号为$SET_PHP_FPM_PORT ..."
                    check_var="^listen = /run/php/php$phpfpmVersion-fpm.sock"
                    if cat "$phpconff" | grep "$check_var" >/dev/null; then
                        # 开始配置
                        backupFile "$phpconff"
                        prompt -x "注释掉listen = /run/php/php$phpfpmVersion-fpm.sock，改为listen=$SET_PHP_FPM_PORT"
                        # 去除开头的^后:
                        tempCheckVar=${check_var#?}
                        # sudo sed -i s@"$check_var"@\; "$tempCheckVar"\\nlisten = SET_PHP_FPM_PORT@g "$phpconff" # 用不了
                        sudo sed -i "s|$check_var|; $tempCheckVar\nlisten = $SET_PHP_FPM_PORT|g" "$phpconff"
                    else
                        # 如果没找到那句话就搜索有无listen开头的参数
                        check_var="^listen = "
                        idx=$(cat "$phpconff" | grep -n "$check_var" | gawk '{print $1}' FS=":")
                        idxl=($idx)
                        idxlen=${#idxl[@]}
                        # 解析行号
                        if [ $idxlen -eq 1 ]; then
                            backupFile "$phpconff"
                            sudo sed -i "$idx d" "$phpconff"
                            sudo sed -i "$idx i listen = $SET_PHP_FPM_PORT" "$phpconff"
                            sudo systemctl restart php"$phpfpmVersion"-fpm.service
                        elif [ $idxlen -eq 0 ]; then
                            prompt -e "在php fpm配置文件中没有找到listen参数,请自行检查配置文件!!"
                        else
                            prompt -e "Find duplicate user setting in $phpconff ! Check manually!"
                        fi
                    fi
                fi
                # 配置php fpm是否开机启动
                if [ "$SET_PHP_FPM_ENABLE" -eq 0 ]; then
                    # php8.2-fpm.service
                    prompt -x "Disable php-fpm service."
                    sudo systemctl disable php"$phpfpmVersion"-fpm.service
                elif [ "$SET_PHP_FPM_ENABLE" -eq 1 ]; then
                    prompt -x "Enable php-fpm service."
                    sudo systemctl enable php"$phpfpmVersion"-fpm.ser vice
                fi
            else
                prompt -e "phpfpm没有/etc/php/*/fpm/pool.d/www.conf 文件!"
                # 这里不退出
                # quitThis
            fi
            # 回到原来的目录
            cd "$fromp"
        fi
    else
        prompt -e "Php似乎安装失败了。"
        quitThis
    fi
fi

# 安装配置Nginx
if [ "$SET_INSTALL_NGINX" -eq 1 ]; then
    # 首先停止Apache2
    if [ -x "$(command -v apache2ctl)" ]; then
        prompt -x 'Stop apache2...'
        sudo systemctl stop apache2.service
        sudo systemctl disable apache2.service
    fi
    prompt -x "Install nginx..."
    doApt install nginx
    # 注意：！！如果要修改根目录请同步修改所有/home/HTML(上面Nginx配置也有)
    prompt -m "配置Nginx 共享目录为 /home/HTML"
    addFolder /home/HTML
    prompt -x "设置/home/HTML读写权限为755"
    sudo chmod 755 /home/HTML
    sudo chown "$CURRENT_USER" /home/HTML
    sudo chgrp "$CURRENT_USER" /home/HTML
    # 安装无问题，开始修改配置文件
    if [ "$?" -eq 0 ]; then
        backupFile /etc/nginx/nginx.conf
        backupFile /etc/nginx/sites-available/default

        prompt -i "Set up a new nginx.conf"
        # replace_username "nginx.conf.src"
        replace_placeholders_with_values "nginx.conf.src"
        sudo cp "nginx.conf" /etc/nginx/nginx.conf
        sudo cp "block_ip.conf" /etc/nginx/block_ip.conf
        sudo cp "SelectNginxSites.sh" /etc/nginx/

        prompt -i "Genarate a http website."
        sudo cp "http" /etc/nginx/sites-available/http
        # 禁用默认的配置文件，启用新的
        prompt -x "Disable default site and Enable nginx https site."
        if [ -f /etc/nginx/sites-enabled/default ]; then
            sudo rm /etc/nginx/sites-enabled/default
        fi
        if ! [ -f /etc/nginx/sites-enabled/http ]; then
            # 请使用绝对路径
            sudo ln -s /etc/nginx/sites-available/http /etc/nginx/sites-enabled/http
        fi
        # 配置是否开机启动
        if [ "$SET_ENABLE_NGINX" -eq 0 ]; then
            prompt -x "Disable Nginx service."
            sudo systemctl disable nginx.service
        elif [ "$SET_ENABLE_NGINX" -eq 1 ]; then
            prompt -x "Enable Nginx service."
            sudo systemctl enable nginx.service
        fi
    else
        prompt -e "Nginx's installation seems failed."
        quitThis
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

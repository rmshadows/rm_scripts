: <<检查点五
安装配置php-fpm
安装http服务器
检查点五

source "cfg.sh"

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

if [ "$SET_INSTALL_HTTP_SERVER" -ne 0 ]; then
    prompt -m "Set share directory $SET_HTTP_SERVER_ROOT "
    addFolder "$SET_HTTP_SERVER_ROOT"
    addFolder "$SET_HTTP_SERVER_ROOT/home_page"
    addFolder "$SET_HTTP_SERVER_ROOT/nres"
    addFolder "$SET_HTTP_SERVER_ROOT/res"
    prompt -x "Set $SET_HTTP_SERVER_ROOT mode 755"
    chmod 755 "$SET_HTTP_SERVER_ROOT"
    chmod 755 "$SET_HTTP_SERVER_ROOT/home_page"
    chmod 755 "$SET_HTTP_SERVER_ROOT/nres"
    chmod 755 "$SET_HTTP_SERVER_ROOT/res"
    prompt -x "Set $SET_HTTP_SERVER_ROOT own by $CURRENT_USER"
    chown "$CURRENT_USER" "$SET_HTTP_SERVER_ROOT"
    chown "$CURRENT_USER" "$SET_HTTP_SERVER_ROOT/home_page"
    chown "$CURRENT_USER" "$SET_HTTP_SERVER_ROOT/nres"
    chown "$CURRENT_USER" "$SET_HTTP_SERVER_ROOT/res"

    chgrp "$CURRENT_USER" "$SET_HTTP_SERVER_ROOT"
    chgrp "$CURRENT_USER" "$SET_HTTP_SERVER_ROOT/home_page"
    chgrp "$CURRENT_USER" "$SET_HTTP_SERVER_ROOT/nres"
    chgrp "$CURRENT_USER" "$SET_HTTP_SERVER_ROOT/res"
fi

# 安装HTTP Server
if [ "$SET_INSTALL_HTTP_SERVER" -eq 1 ]; then
    # 检查apache2，存在就停止运行
    if [ -x "$(command -v apache2ctl)" ]; then
        prompt -x 'Stop apache2...' >&2
        systemctl stop apache2.service
        systemctl disable apache2.service
    fi
    prompt -x "Install nginx..."
    doApt install nginx
    addFolder "$HOME_INDEX/Logs/nginx"                       # for nginx
    sudo chown -R www-data:www-data "$HOME_INDEX/Logs/nginx" # 适配你的Nginx用户组
    sudo chmod 755 "$HOME_INDEX/Logs/nginx"

    # 安装软件包，未后面加密目录做准备
    if ! [ -x "$(command -v htpasswd)" ]; then
        prompt -x 'Install apache2-utils...'
        doApt install apache2-utils
    fi
    prompt -x "Generate a passwd file at user home."
    htpasswd -bc "$HOME_INDEX"/nginx_res_login $SET_NGINX_RES_USER $SET_NGINX_RES_PASSWD
    if [ $? -eq 0 ]; then
        backupFile /etc/nginx/nginx.conf
        backupFile /etc/nginx/sites-available/default
        prompt -i "Set up a new nginx.conf"
        # replace_username "nginx/nginx.conf.src"
        replace_placeholders_with_values "nginx/nginx.conf.src"
        sudo cp "nginx/nginx.conf" /etc/nginx/nginx.conf
        sudo cp "nginx/block_ip.conf" /etc/nginx/block_ip.conf
        sudo cp "nginx/SelectNginxSites.sh" /etc/nginx/
        # 生成站点
        prompt -i "Genarate a http website and a https website."
        prompt -i "Genarate a http website."

        prompt -i "Genarate a https website."
        sudo cp "http" /etc/nginx/sites-available/http

        echo "$NGINX_HTTP_SITE" >/etc/nginx/sites-available/http
        echo "$NGINX_HTTPS_SITE" >/etc/nginx/sites-available/https
        if [ "$SET_ENABLE_HTTPS_SITE" -eq 1 ]; then
            prompt -x "Disable default site and Enable nginx https site."
            if [ -f /etc/nginx/sites-enabled/default ]; then
                rm /etc/nginx/sites-enabled/default
            fi
            if ! [ -f /etc/nginx/sites-enabled/https ]; then
                # 请使用绝对路径
                ln -s /etc/nginx/sites-available/https /etc/nginx/sites-enabled/https
            fi
        fi
        if [ "$SET_ENABLE_HTTP_SERVICE" -eq 0 ]; then
            prompt -x "Disable Nginx service."
            systemctl disable nginx.service
        elif [ "$SET_ENABLE_HTTP_SERVICE" -eq 1 ]; then
            prompt -x "Enable Nginx service."
            systemctl enable nginx.service
        fi
    else
        prompt -e "Nginx's installation seems failed."
        exit 1
    fi
elif [ "$SET_INSTALL_HTTP_SERVER" -eq 2 ]; then
    if [ -x "$(command -v nginx)" ]; then
        prompt -x 'Stop nginx...' >&2
        systemctl stop nginx.service
        systemctl disable nginx.service
    fi
    prompt -x "安装Apache2"
    addFolder "$HOME_INDEX/Logs/apache2" # for apache2
    doApt install apache2
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

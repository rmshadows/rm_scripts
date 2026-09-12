: <<检查点五
安装配置php-fpm
安装http服务器
配置LetsEncrypt Certbot / acme.sh
检查点五

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
                    sudo systemctl enable php"$phpfpmVersion"-fpm.service
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
    doApt remove apache2
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
        # 不存在才会生成站点
        if ! [ -f "/etc/nginx/sites-available/http" ]; then
            prompt -i "Genarate a http website and a https website."
            replace_placeholders_with_values "nginx/http.src"
            prompt -i "Genarate a http website."
            sudo cp "nginx/http" "/etc/nginx/sites-available/http"
        else
            prompt -w "已经存在http站点，不再重复生成！"
        fi
        if ! [ -f "/etc/nginx/sites-available/https" ]; then
            # 配置https站点
            prompt -i "Genarate a https website."
            replace_placeholders_with_values "nginx/https.src"
            sudo cp "nginx/https" "/etc/nginx/sites-available/https"
        else
            prompt -w "已经存在https站点，不再重复生成！"
        fi
        # 启用站点
        if [ "$SET_ENABLE_SITE" -ne 0 ]; then
            prompt -x "Disable default site."
            if [ -f /etc/nginx/sites-enabled/default ]; then
                rm /etc/nginx/sites-enabled/default
            fi
        fi
        if [ "$SET_ENABLE_SITE" -eq 1 ]; then
            prompt -x "Enable nginx http site."
            if ! [ -f /etc/nginx/sites-enabled/http ]; then
                # 请使用绝对路径
                ln -s /etc/nginx/sites-available/http /etc/nginx/sites-enabled/http
            fi
        elif [ "$SET_ENABLE_SITE" -eq 2 ]; then
            prompt -x "Enable nginx https site."
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
        quitThis
    fi
elif [ "$SET_INSTALL_HTTP_SERVER" -eq 2 ]; then
    if [ -x "$(command -v nginx)" ]; then
        prompt -x 'Stop nginx...' >&2
        systemctl stop nginx.service
        systemctl disable nginx.service
    fi
    doApt remove nginx
    prompt -x "安装Apache2"
    addFolder "$HOME_INDEX/Logs/apache2" # for apache2
    doApt install apache2
    if [ $? -eq 0 ]; then
        backupFile /etc/apache2/apache2.conf
        prompt -i "Set up a new apache2.conf"
        replace_placeholders_with_values "apache2/apache2.conf.src"
        sudo cp "apache2/apache2.conf" /etc/apache2/apache2.conf
        # 配置站点
        prompt -i "Set up a http.conf"
        replace_placeholders_with_values "apache2/http.conf.src"
        sudo cp "apache2/http" "/etc/apache2/sites-available/http"
        prompt -i "Set up a https.conf"
        replace_placeholders_with_values "apache2/https.conf.src"
        sudo cp "apache2/https" "/etc/apache2/sites-available/https"

        # 检查 a2ensite 命令是否可用
        if command -v a2ensite &>/dev/null; then
            if [ "$SET_ENABLE_SITE" -ne 0 ]; then
                prompt -x "Disable default site."
                if [ -f /etc/nginx/sites-enabled/default ]; then
                    sudo a2dissite 000-default.conf
                fi
            fi
            # 如果 a2ensite 存在，使用它启用或禁用站点
            if [ "$SET_ENABLE_SITE" -ne 1 ]; then
                sudo a2ensite http
            elif [ "$SET_ENABLE_SITE" -ne 2 ]; then
                sudo a2ensite https
            fi
        else
            # 手动启用站点
            if [ "$SET_ENABLE_SITE" -ne 0 ]; then
                prompt -x "Disable default site."
                if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
                    sudo rm /etc/apache2/sites-enabled/000-default.conf
                fi
            fi
            # 如果没有 a2ensite，手动创建符号链接
            tAPACHE_CONF_DIR="/etc/apache2/sites-available"
            tAPACHE_ENABLED_DIR="/etc/apache2/sites-enabled"
            if [ "$SET_ENABLE_SITE" -ne 1 ]; then
                sudo ln -s "$APACHE_CONF_DIR/http.conf" "$APACHE_ENABLED_DIR/http.conf"
            elif [ "$SET_ENABLE_SITE" -ne 2 ]; then
                sudo ln -s "$APACHE_CONF_DIR/https.conf" "$APACHE_ENABLED_DIR/https.conf"
            fi
        fi
        if [ "$SET_ENABLE_HTTP_SERVICE" -eq 0 ]; then
            prompt -x "禁用Apache2服务开机自启"
            sudo systemctl disable apache2.service
        elif [ "$SET_ENABLE_HTTP_SERVICE" -eq 1 ]; then
            prompt -x "配置Apache2服务开机自启"
            sudo systemctl enable apache2.service
        fi
    else
        prompt -e "Apache2似乎安装失败了。"
        quitThis
    fi
fi

# Ｌｅｔ‘ｓ　Ｅｎｃｒｙｐｔ　Ｃｅｒｔ　Ｂｏｔ
# https://letsencrypt.org/zh-cn/
# https://certbot.eff.org/instructions?ws=nginx&os=pip&tab=standard
if [ "$SET_INSTALL_CERTBOT" -eq 1 ]; then
    doApt update
    doApt install python3 python3-venv libaugeas0
    # Set up a Python virtual environment
    sudo python3 -m venv /opt/certbot/
    sudo /opt/certbot/bin/pip install --upgrade pip
    if [ "$SET_INSTALL_HTTP_SERVER" -eq 1 ]; then
        sudo /opt/certbot/bin/pip install certbot certbot-nginx
        prompt -i "Run this command to get a certificate and have Certbot edit your nginx configuration automatically to serve it, turning on HTTPS access in a single step."
        prompt -i "sudo certbot --nginx"
    elif [ "$SET_INSTALL_HTTP_SERVER" -eq 2 ]; then
        sudo /opt/certbot/bin/pip install certbot certbot-apache
        prompt -i "Run this command to get a certificate and have Certbot edit your nginx configuration automatically to serve it, turning on HTTPS access in a single step."
        prompt -i "sudo certbot --apache"
    fi
    prompt -i "Set up automatic renewal manually:"
    echo "echo \"0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && sudo certbot renew -q\" | sudo tee -a /etc/crontab > /dev/null"
    sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
    # 后续步骤
    # Either get and install your certificates...
    # Run this command to get a certificate and have Certbot edit your nginx configuration automatically to serve it, turning on HTTPS access in a single step.
    # sudo certbot --nginx
    # Or, just get a certificate
    # If you're feeling more conservative and would like to make the changes to your nginx configuration by hand, run this command.
    # sudo certbot certonly --nginx
    # echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && sudo certbot renew -q" | sudo tee -a /etc/crontab > /dev/null
    # Upgrade:　sudo /opt/certbot/bin/pip install --upgrade certbot certbot-nginx
fi

# acme.sh（https://github.com/acmesh-official/acme.sh ）
# 官方安装：curl https://get.acme.sh | sh ；此处只安装，不自动签发
if [ "$SET_INSTALL_ACME_SH" -eq 1 ]; then
    if [ "$SET_INSTALL_CERTBOT" -eq 1 ]; then
        prompt -w "同时启用了 Certbot 与 acme.sh，一般只需其一；两者都会安装"
    fi
    prompt -x "安装 acme.sh 到 $SET_ACME_HOME （账户邮箱: $SET_ACME_EMAIL）"
    doApt install curl cron

    if [ -x "$SET_ACME_HOME/acme.sh" ]; then
        prompt -m "已检测到 $SET_ACME_HOME/acme.sh ，跳过下载安装"
    else
        if [ "$SET_ACME_CERT_HOME" != "0" ] && [ -n "$SET_ACME_CERT_HOME" ]; then
            sudo -H -u "$CURRENT_USER" mkdir -p "$SET_ACME_CERT_HOME" 2>/dev/null || addFolder "$SET_ACME_CERT_HOME"
        fi
        sudo -H -u "$CURRENT_USER" mkdir -p "$SET_ACME_HOME" 2>/dev/null || addFolder "$SET_ACME_HOME"
        # root 跑部署时 addFolder 可能把目录建成 root 的，安装用户写不进去
        if [ "$(id -u)" -eq 0 ] && [ "$(id -un)" != "$CURRENT_USER" ]; then
            chown -R "$CURRENT_USER:" "$SET_ACME_HOME" 2>/dev/null || true
            [ -n "$SET_ACME_CERT_HOME" ] && [ "$SET_ACME_CERT_HOME" != "0" ] && \
                chown -R "$CURRENT_USER:" "$SET_ACME_CERT_HOME" 2>/dev/null || true
        fi

        # 不走 get.acme.sh | sh -s -- --home：官方脚本会把 -- 和 --home 拼成 ----home。
        # 也不在检查点 cwd（/root/.../5）解压。改为 /tmp 下下载 tarball，再 ./acme.sh --install。
        _acme_tmp=$(mktemp -d /tmp/acme-sh-XXXXXX)
        chmod 755 "$_acme_tmp"
        if [ "$(id -u)" -eq 0 ] && [ "$(id -un)" != "$CURRENT_USER" ]; then
            chown "$CURRENT_USER:" "$_acme_tmp"
        fi
        _acme_tmp_q=$(printf '%q' "$_acme_tmp")
        _acme_home_q=$(printf '%q' "$SET_ACME_HOME")
        _acme_mail_q=$(printf '%q' "$SET_ACME_EMAIL")
        _acme_install_cmd="./acme.sh --install --home ${_acme_home_q} --accountemail ${_acme_mail_q}"
        if [ "$SET_ACME_CERT_HOME" != "0" ] && [ -n "$SET_ACME_CERT_HOME" ]; then
            _acme_install_cmd+=" --cert-home $(printf '%q' "$SET_ACME_CERT_HOME")"
        fi
        _acme_fetch_cmd="curl -fsSL https://github.com/acmesh-official/acme.sh/archive/master.tar.gz -o ${_acme_tmp_q}/acme.sh.tar.gz && tar -xzf ${_acme_tmp_q}/acme.sh.tar.gz -C ${_acme_tmp_q}"
        prompt -m "下载 acme.sh 到 $_acme_tmp ，以用户 $CURRENT_USER 安装"
        if [ "$(id -un)" = "$CURRENT_USER" ]; then
            bash -c "$_acme_fetch_cmd"
            _acme_rc=$?
        else
            sudo -H -u "$CURRENT_USER" bash -c "$_acme_fetch_cmd"
            _acme_rc=$?
        fi
        _acme_src=""
        if [ "$_acme_rc" -eq 0 ]; then
            _acme_src=$(find "$_acme_tmp" -maxdepth 2 -type f -name acme.sh 2>/dev/null | head -n 1)
        fi
        if [ -n "$_acme_src" ] && [ -f "$_acme_src" ]; then
            _acme_src_dir=$(dirname "$_acme_src")
            _acme_src_dir_q=$(printf '%q' "$_acme_src_dir")
            if [ "$(id -un)" = "$CURRENT_USER" ]; then
                bash -c "cd ${_acme_src_dir_q} && ${_acme_install_cmd}"
                _acme_rc=$?
            else
                sudo -H -u "$CURRENT_USER" bash -c "cd ${_acme_src_dir_q} && ${_acme_install_cmd}"
                _acme_rc=$?
            fi
        else
            _acme_rc=1
        fi
        rm -rf "$_acme_tmp"
        if [ "$_acme_rc" -ne 0 ] || [ ! -x "$SET_ACME_HOME/acme.sh" ]; then
            prompt -e "acme.sh 安装失败。需能访问 GitHub（acmesh-official/acme.sh），并以用户 $CURRENT_USER 写入 $SET_ACME_HOME。"
            quitThis
        fi
        unset _acme_tmp _acme_tmp_q _acme_home_q _acme_mail_q _acme_install_cmd _acme_fetch_cmd _acme_src _acme_src_dir _acme_src_dir_q _acme_rc
    fi

    # 方便全局调用（仍建议带 --home，或 source acme.sh.env）
    if [ -x "$SET_ACME_HOME/acme.sh" ]; then
        sudo ln -sfn "$SET_ACME_HOME/acme.sh" /usr/local/bin/acme.sh
    fi

    if [ "$SET_ACME_DEFAULT_CA" -eq 1 ]; then
        prompt -x "设置 acme.sh 默认 CA 为 Let's Encrypt"
        sudo -H -u "$CURRENT_USER" "$SET_ACME_HOME/acme.sh" --home "$SET_ACME_HOME" --set-default-ca --server letsencrypt || \
            "$SET_ACME_HOME/acme.sh" --home "$SET_ACME_HOME" --set-default-ca --server letsencrypt
    elif [ "$SET_ACME_DEFAULT_CA" -eq 2 ]; then
        prompt -x "设置 acme.sh 默认 CA 为 ZeroSSL"
        sudo -H -u "$CURRENT_USER" "$SET_ACME_HOME/acme.sh" --home "$SET_ACME_HOME" --set-default-ca --server zerossl || \
            "$SET_ACME_HOME/acme.sh" --home "$SET_ACME_HOME" --set-default-ca --server zerossl
    fi

    _acme_webroot="$SET_HTTP_SERVER_ROOT"
    if [ "$SET_ACME_CERT_HOME" = "0" ] || [ -z "$SET_ACME_CERT_HOME" ]; then
        _acme_cert_home_desc="默认随安装目录"
    else
        _acme_cert_home_desc="$SET_ACME_CERT_HOME"
    fi
    if [ "$SET_INSTALL_HTTP_SERVER" -eq 1 ]; then
        _acme_reload='systemctl reload nginx'
        _acme_install_cert_hint="$SET_ACME_HOME/acme.sh --install-cert -d 你的域名 \\
  --key-file /etc/ssl/你的域名.key \\
  --fullchain-file /etc/ssl/你的域名.pem \\
  --reloadcmd \"${_acme_reload}\""
    elif [ "$SET_INSTALL_HTTP_SERVER" -eq 2 ]; then
        _acme_reload='systemctl reload apache2'
        _acme_install_cert_hint="$SET_ACME_HOME/acme.sh --install-cert -d 你的域名 \\
  --key-file /etc/ssl/你的域名.key \\
  --fullchain-file /etc/ssl/你的域名.pem \\
  --reloadcmd \"${_acme_reload}\""
    else
        _acme_reload='true'
        _acme_install_cert_hint="（未安装 http 服务器，请自行指定 --reloadcmd 与证书路径）"
    fi

    _acme_readme="$SET_ACME_HOME/README-Debian_Server_Init.md"
    _acme_readme_home="$HOME_INDEX/acme.sh使用说明.md"
    _acme_issue_hint="$SET_ACME_HOME/acme.sh --issue -d 你的域名 -w ${_acme_webroot} --reloadcmd \"${_acme_reload}\""

    # 写入说明文件（安装目录 + 家目录各一份，跑完脚本也好找）
    _acme_readme_body="# acme.sh 使用说明（由 Debian_Server_Init 生成）

脚本只负责**安装** acme.sh，**不会自动签发**证书。签发需域名已解析到本机，且 HTTP 校验路径可访问。

## 安装位置

- 程序目录: \`$SET_ACME_HOME\`
- 可执行文件: \`$SET_ACME_HOME/acme.sh\`（另有软链 \`/usr/local/bin/acme.sh\`）
- 账户邮箱: \`$SET_ACME_EMAIL\`
- 证书目录: \`${_acme_cert_home_desc}\`
- 环境变量: \`source $SET_ACME_HOME/acme.sh.env\`（或重新登录）
- 本说明副本: \`$SET_ACME_HOME/README-Debian_Server_Init.md\`
- 家目录快捷: \`$HOME_INDEX/acme.sh使用说明.md\`

官方文档: https://github.com/acmesh-official/acme.sh

## 签发证书（示例）

\`\`\`bash
source $SET_ACME_HOME/acme.sh.env
# 或: $SET_ACME_HOME/acme.sh --home $SET_ACME_HOME ...

$_acme_issue_hint
\`\`\`

当前配置参考域名 \`SET_SERVER_NAME=$SET_SERVER_NAME\`，webroot=\`${_acme_webroot}\`。

## 把证书装到 Web 服务器常用路径（示例）

\`\`\`bash
$_acme_install_cert_hint
\`\`\`

然后在站点配置里指向上述 key / fullchain（本仓库 nginx https 模板常用 \`/etc/ssl/\$域名.pem\`）。

## 续期

安装时一般已写入用户 cron（\`crontab -l\` 可见）。手动检查：

\`\`\`bash
$SET_ACME_HOME/acme.sh --cron --home $SET_ACME_HOME
\`\`\`

## 卸载

\`\`\`bash
# 1) 卸掉 acme.sh（会清 cron 相关项）
$SET_ACME_HOME/acme.sh --uninstall --home $SET_ACME_HOME

# 2) 删除安装目录（按需）
rm -rf $SET_ACME_HOME

# 3) 删除软链（若存在）
sudo rm -f /usr/local/bin/acme.sh

# 4) 删除本说明（可选）
rm -f \"$HOME_INDEX/acme.sh使用说明.md\"
\`\`\`

已签发的证书若在其它目录（如 \`/etc/ssl/\`），需自行删除站点 SSL 配置与证书文件。
"

    if [ "$(id -un)" = "$CURRENT_USER" ]; then
        printf '%s\n' "$_acme_readme_body" >"$_acme_readme"
        printf '%s\n' "$_acme_readme_body" >"$_acme_readme_home"
    else
        printf '%s\n' "$_acme_readme_body" | sudo -H -u "$CURRENT_USER" tee "$_acme_readme" >/dev/null
        printf '%s\n' "$_acme_readme_body" | sudo -H -u "$CURRENT_USER" tee "$_acme_readme_home" >/dev/null
    fi

    prompt -s "acme.sh 已安装。使用/卸载说明已写入："
    prompt -k "  →" "$_acme_readme_home"
    prompt -k "  →" "$_acme_readme"
    prompt -i "续期由 cron 负责；重新登录或: source $SET_ACME_HOME/acme.sh.env"
    prompt -i "签发示例: $_acme_issue_hint"
    unset _acme_webroot _acme_reload _acme_install_cert_hint _acme_readme _acme_readme_home _acme_issue_hint _acme_readme_body _acme_cert_home_desc
fi

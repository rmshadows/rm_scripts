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
        deploy_install_exec "nginx/SelectNginxSites.sh" /etc/nginx/ngx-site
        ln -sfn /etc/nginx/ngx-site /usr/local/bin/ngx-site
        sudo cp "nginx/SITES.txt" /etc/nginx/sites-available/README.txt
        # 旧名 http / https → acme.conf / ssl.conf
        if [ -L /etc/nginx/sites-enabled/http ] || [ -L /etc/nginx/sites-enabled/https ]; then
            rm -f /etc/nginx/sites-enabled/http /etc/nginx/sites-enabled/https
        fi
        if [ -f /etc/nginx/sites-available/http ]; then
            backupFile /etc/nginx/sites-available/http
        fi
        if [ -f /etc/nginx/sites-available/https ] && [ ! -f /etc/nginx/sites-available/ssl.conf ]; then
            mv /etc/nginx/sites-available/https /etc/nginx/sites-available/ssl.conf
            prompt -m "已将旧的 sites-available/https 改名为 ssl.conf"
        fi
        addFolder "$SET_HTTP_SERVER_ROOT/.well-known/acme-challenge"
        chmod o+x "$HOME_INDEX" 2>/dev/null || true
        chmod 755 "$SET_HTTP_SERVER_ROOT" "$SET_HTTP_SERVER_ROOT/.well-known" \
            "$SET_HTTP_SERVER_ROOT/.well-known/acme-challenge" 2>/dev/null || true
        prompt -i "写入 acme.conf（80：校验 + 测试页）"
        replace_placeholders_with_values "nginx/acme.conf.src"
        sudo cp "nginx/acme.conf" /etc/nginx/sites-available/acme.conf
        if [ ! -f /etc/nginx/sites-available/ssl.conf ]; then
            prompt -i "写入 ssl.conf（443 模板，默认不启用）"
            replace_placeholders_with_values "nginx/ssl.conf.src"
            sudo cp "nginx/ssl.conf" /etc/nginx/sites-available/ssl.conf
        else
            prompt -w "已有 ssl.conf，不覆盖。签发后改它，再 sudo ngx-site 启用。"
        fi
        if [ "$SET_ENABLE_SITE" -ne 0 ]; then
            prompt -x "关掉 Debian 默认 default 站点"
            rm -f /etc/nginx/sites-enabled/default
        fi
        # 80 的 acme.conf：只要开 HTTP 服务就启用（续期需要）
        if [ "$SET_ENABLE_SITE" -ge 1 ]; then
            prompt -x "启用 acme.conf"
            ln -sfn /etc/nginx/sites-available/acme.conf /etc/nginx/sites-enabled/acme.conf
        fi
        if [ "$SET_ENABLE_SITE" -eq 2 ]; then
            prompt -x "启用 ssl.conf（请确认 /etc/ssl 下已有证书）"
            ln -sfn /etc/nginx/sites-available/ssl.conf /etc/nginx/sites-enabled/ssl.conf
        fi
        deploy_ufw_sync_ports
        if [ "$SET_ENABLE_HTTP_SERVICE" -eq 0 ]; then
            prompt -x "Disable Nginx service."
            systemctl disable nginx.service
        elif [ "$SET_ENABLE_HTTP_SERVICE" -eq 1 ]; then
            prompt -x "Enable and start Nginx（ACME 需要 80 已在听）。"
            if nginx -t; then
                systemctl enable --now nginx.service
                systemctl reload nginx.service || true
            else
                prompt -e "nginx -t 失败，未启动。请检查站点配置。"
                quitThis
            fi
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
        deploy_ufw_sync_ports
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
# 安装后若 SET_ACME_ISSUE=1 且域名为真，则用 HTTP-01 签发；不自动启用 https 站点。
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
            deploy_as_acme_user mkdir -p "$SET_ACME_CERT_HOME" 2>/dev/null || addFolder "$SET_ACME_CERT_HOME"
        fi
        deploy_as_acme_user mkdir -p "$SET_ACME_HOME" 2>/dev/null || addFolder "$SET_ACME_HOME"
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
        prompt -m "下载 acme.sh 到 $_acme_tmp ，以用户 $CURRENT_USER 安装（不经过 sudo/root）"
        deploy_as_acme_user bash -c "$_acme_fetch_cmd"
        _acme_rc=$?
        _acme_src=""
        if [ "$_acme_rc" -eq 0 ]; then
            _acme_src=$(find "$_acme_tmp" -maxdepth 2 -type f -name acme.sh 2>/dev/null | head -n 1)
        fi
        if [ -n "$_acme_src" ] && [ -f "$_acme_src" ]; then
            _acme_src_dir=$(dirname "$_acme_src")
            _acme_src_dir_q=$(printf '%q' "$_acme_src_dir")
            deploy_as_acme_user bash -c "cd ${_acme_src_dir_q} && ${_acme_install_cmd}"
            _acme_rc=$?
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

    # /usr/local/bin/acme.sh：拒绝 root/sudo，避免误跑
    if [ -x "$SET_ACME_HOME/acme.sh" ]; then
        cat >/usr/local/bin/acme.sh <<EOF
#!/bin/bash
if [ "\$(id -u)" -eq 0 ] || [ -n "\${SUDO_USER:-}" ]; then
    echo "acme.sh 不能用 root 或 sudo 跑。请先切换到业务用户（Config 里的 CURRENT_USER）。" >&2
    exit 1
fi
exec "$SET_ACME_HOME/acme.sh" --home "$SET_ACME_HOME" "\$@"
EOF
        chmod 755 /usr/local/bin/acme.sh
    fi

    if [ "$SET_ACME_DEFAULT_CA" -eq 1 ]; then
        prompt -x "设置 acme.sh 默认 CA 为 Let's Encrypt"
        deploy_run_acme --set-default-ca --server letsencrypt || true
    elif [ "$SET_ACME_DEFAULT_CA" -eq 2 ]; then
        prompt -x "设置 acme.sh 默认 CA 为 ZeroSSL"
        deploy_run_acme --set-default-ca --server zerossl || true
    fi

    _acme_webroot="$SET_HTTP_SERVER_ROOT"
    if [ "$SET_ACME_CERT_HOME" = "0" ] || [ -z "$SET_ACME_CERT_HOME" ]; then
        _acme_cert_home_desc="默认随安装目录"
        _acme_cert_root="$SET_ACME_HOME"
    else
        _acme_cert_home_desc="$SET_ACME_CERT_HOME"
        _acme_cert_root="$SET_ACME_CERT_HOME"
    fi
    if [ "$SET_INSTALL_HTTP_SERVER" -eq 1 ]; then
        _acme_http=nginx
    elif [ "$SET_INSTALL_HTTP_SERVER" -eq 2 ]; then
        _acme_http=apache2
    else
        _acme_http=none
    fi
    # 普通用户跑 acme.sh / cron 不能 systemctl reload，也不能写 /etc/ssl。
    # 用 root 助手 + sudoers 免密：拷证书并 reload。
    cat >/etc/acme-deploy.conf <<EOF
ACME_USER=$CURRENT_USER
ACME_HOME=$_acme_cert_root
HTTP=$_acme_http
EOF
    chmod 644 /etc/acme-deploy.conf
    deploy_install_exec "acme-deploy-cert.sh" /usr/local/sbin/acme-deploy-cert
    _acme_sudoers=/etc/sudoers.d/acme-deploy-cert
    cat >"$_acme_sudoers" <<EOF
Defaults:${CURRENT_USER} !requiretty
${CURRENT_USER} ALL=(root) NOPASSWD: /usr/local/sbin/acme-deploy-cert
EOF
    chmod 440 "$_acme_sudoers"
    if ! visudo -cf "$_acme_sudoers" >/dev/null 2>&1; then
        prompt -e "写入 sudoers 失败，已删除 $_acme_sudoers"
        rm -f "$_acme_sudoers"
    fi
    unset _acme_sudoers
    _acme_reload='sudo -n /usr/local/sbin/acme-deploy-cert'
    _acme_install_cert_hint="$SET_ACME_HOME/acme.sh --home $SET_ACME_HOME --install-cert -d 你的域名 --reloadcmd \"${_acme_reload}\""

    _acme_readme="$SET_ACME_HOME/使用说明.md"
    _acme_readme_home="$HOME_INDEX/acme.sh使用说明.md"
    _acme_issue_hint="$SET_ACME_HOME/acme.sh --home $SET_ACME_HOME --issue -d ${SET_SERVER_NAME} -w ${_acme_webroot}"

    _acme_issued=0
    if [ "${SET_ACME_ISSUE:-0}" -eq 1 ]; then
        _acme_http_up=0
        if [ "$SET_INSTALL_HTTP_SERVER" -eq 1 ] && systemctl is-active --quiet nginx; then
            _acme_http_up=1
        elif [ "$SET_INSTALL_HTTP_SERVER" -eq 2 ] && systemctl is-active --quiet apache2; then
            _acme_http_up=1
        fi
        if ! deploy_acme_domain_usable "$SET_SERVER_NAME"; then
            prompt -w "SET_ACME_ISSUE=1，但 SET_SERVER_NAME=$SET_SERVER_NAME 不能签 Let's Encrypt。填已解析到本机的域名后再签发。"
        elif [ "$_acme_http_up" -ne 1 ]; then
            prompt -w "HTTP 服务未在运行，跳过自动签发。"
        else
            prompt -x "自动签发 $SET_SERVER_NAME （webroot=${_acme_webroot}，不启用 https 站点）"
            deploy_run_acme --issue -d "$SET_SERVER_NAME" -w "$_acme_webroot"
            _acme_issue_rc=$?
            # 0=新签 2=已有且未到期
            if [ "$_acme_issue_rc" -eq 0 ] || [ "$_acme_issue_rc" -eq 2 ]; then
                # acme.sh 只登记 reloadcmd；写 /etc/ssl 和 reload 由助手做（助手不是 acme.sh）。
                deploy_run_acme --install-cert -d "$SET_SERVER_NAME" --reloadcmd "$_acme_reload" || true
                for _acme_conf in \
                    "$SET_ACME_HOME/${SET_SERVER_NAME}_ecc/${SET_SERVER_NAME}.conf" \
                    "$SET_ACME_HOME/${SET_SERVER_NAME}/${SET_SERVER_NAME}.conf"; do
                    if [ -f "$_acme_conf" ]; then
                        deploy_as_acme_user sed -i \
                            -e "s|^Le_RealKeyPath=.*|Le_RealKeyPath=''|" \
                            -e "s|^Le_RealFullChainPath=.*|Le_RealFullChainPath=''|" \
                            -e "s|^Le_RealCertPath=.*|Le_RealCertPath=''|" \
                            -e "s|^Le_RealCACertPath=.*|Le_RealCACertPath=''|" \
                            "$_acme_conf"
                    fi
                done
                unset _acme_conf
                /usr/local/sbin/acme-deploy-cert "$SET_SERVER_NAME" || true
                _acme_issued=1
                prompt -s "证书已放到 /etc/ssl/${SET_SERVER_NAME}.pem 与 .key"
                prompt -i "接下来改 /etc/nginx/sites-available/ssl.conf ，然后： sudo ngx-site"
            else
                prompt -e "自动签发失败（检查域名 A 记录、80 端口、UFW）。部署继续，可稍后手动签发。"
            fi
        fi
        unset _acme_http_up _acme_issue_rc
    fi

    # 写入说明文件（安装目录 + 家目录各一份，跑完脚本也好找）
    _acme_readme_body="$(cat <<EOF
# 证书与 Nginx（Debian_Server_Init）

域名: ${SET_SERVER_NAME}
邮箱: ${SET_ACME_EMAIL}
证书: /etc/ssl/${SET_SERVER_NAME}.pem
密钥: /etc/ssl/${SET_SERVER_NAME}.key
校验目录: ${_acme_webroot}/.well-known/acme-challenge/
acme.sh: ${SET_ACME_HOME}/acme.sh

## Nginx 两个文件

  acme.conf   80   校验 + 测试页（默认已开，续期要留着）
  ssl.conf    443  正式站（默认不开）

说明也在: /etc/nginx/sites-available/README.txt

## 签发成功后启用 HTTPS

  1. 改站点:  sudo nano /etc/nginx/sites-available/ssl.conf
  2. 启用:    sudo ngx-site
     （选 ssl.conf）
  3. 或手动:
       sudo ln -s /etc/nginx/sites-available/ssl.conf /etc/nginx/sites-enabled/ssl.conf
       sudo nginx -t && sudo systemctl reload nginx

浏览器打开 https://${SET_SERVER_NAME}

## 手动重签（用业务用户，不要 sudo acme.sh）

  acme.sh --issue -d ${SET_SERVER_NAME} -w ${_acme_webroot}
  acme.sh --install-cert -d ${SET_SERVER_NAME} --reloadcmd "${_acme_reload}"

写 /etc/ssl 和 reload 用助手（部署已写入 sudoers，这不是 acme.sh）：

  sudo -n /usr/local/sbin/acme-deploy-cert

不要: sudo acme.sh / sudo -u 用户 acme.sh（官方会拒绝）。

## 续期 / 卸载（同样不要 sudo acme.sh）

  acme.sh --cron
  acme.sh --uninstall

官方: https://github.com/acmesh-official/acme.sh
EOF
)"

    printf '%s\n' "$_acme_readme_body" | deploy_as_acme_user tee "$_acme_readme" >/dev/null
    printf '%s\n' "$_acme_readme_body" | deploy_as_acme_user tee "$_acme_readme_home" >/dev/null

    prompt -s "acme.sh 已安装。使用/卸载说明已写入："
    prompt -k "  →" "$_acme_readme_home"
    prompt -k "  →" "$_acme_readme"
    if [ "${_acme_issued:-0}" -eq 1 ]; then
        prompt -s "已自动签发。请自行启用 HTTPS 站点模板（不会自动 ln -s）。"
    fi
    prompt -i "续期由 cron 负责；重新登录或: source $SET_ACME_HOME/acme.sh.env"
    unset _acme_webroot _acme_reload _acme_install_cert_hint _acme_readme _acme_readme_home _acme_issue_hint _acme_readme_body _acme_cert_home_desc _acme_cert_root _acme_http _acme_issued
fi

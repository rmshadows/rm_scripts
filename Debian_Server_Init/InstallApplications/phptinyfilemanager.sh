#!/bin/bash
# https://github.com/prasathmani/tinyfilemanager    
# 要求非root用户
# 要求sudo git acl
# 详情见readme

# tinyfilemanager的根目录(要求www-data能写入)
TFM_ROOT=$HOME/tiny-file-manager/
# tinyfilemanager配置
TFM_CONFIG="<?php

/*
#################################################################################################################
This is an OPTIONAL configuration file. rename this file into config.php to use this configuration 
The role of this file is to make updating of \"tinyfilemanager.php\" easier.
So you can:
-Feel free to remove completely this file and configure \"tinyfilemanager.php\" as a single file application.
or
-Put inside this file all the static configuration you want and forgot to configure \"tinyfilemanager.php\".
#################################################################################################################
*/

// Auth with login/password
// set true/false to enable/disable it
// Is independent from IP white- and blacklisting
\$use_auth = true;

// Login user name and password
// Users: array('Username' => 'Password', 'Username2' => 'Password2', ...)
// Generate secure password hash - https://tinyfilemanager.github.io/docs/pwd.html
\$auth_users = array(
    'admin' => '\$2y\$10\$6Z2zkL.b7g6EvVemsQdXg.2vn4RL47/fjvbZl8rPbCQQvCm2Qh23C', //admin@123
    'user' => '\$2y\$10\$GoGgZThLG.neMa2oOI1NP.YRReLN/oWIV24Lf3eNVoF5RYR6jlNyO', //12345
    'guest' => '\$2y\$10\$9hkmnPpjDfSSUVv6RT61k.STOyTpznkUmjEovzUCwnL2f7o5MScD6', // guest
    'upload' => '\$2y\$10\$wiD3/d5JmfRk9WJFM9cbA.IDLLOhIm/HvdrMAMnoUr0ES0ioa9A1.' // uploader
);

// Readonly users
// e.g. array('users', 'guest', ...)
\$readonly_users = array(
    'user',
    'guest'
);

// Enable highlight.js (https://highlightjs.org/) on view's page
\$use_highlightjs = true;

// highlight.js style
// for dark theme use 'ir-black'
\$highlightjs_style = 'vs';

// Enable ace.js (https://ace.c9.io/) on view's page
\$edit_files = true;

// Default timezone for date() and time()
// Doc - http://php.net/manual/en/timezones.php
\$default_timezone = 'Asia/Shanghai'; // UTC

// Root path for file manager
// use absolute path of directory i.e: '/var/www/folder' or \$_SERVER['DOCUMENT_ROOT'].'/folder'
// \$root_path = \$_SERVER['DOCUMENT_ROOT'];
\$root_path = \$_SERVER['DOCUMENT_ROOT'].'/files';

// Root url for links in file manager.Relative to \$http_host. Variants: '', 'path/to/subfolder'
// Will not working if \$root_path will be outside of server document root
\$root_url = '';

// Server hostname. Can set manually if wrong
 \$http_host = \$_SERVER['HTTP_HOST'];

// user specific directories
// array('Username' => 'Directory path', 'Username2' => 'Directory path', ...)
\$directories_users = array(
    'upload' => 'files/temp'
);

// input encoding for iconv
\$iconv_input_encoding = 'UTF-8';

// date() format for file modification date
// Doc - https://www.php.net/manual/en/datetime.format.php
// \$datetime_format = 'd.m.y H:i:s';
\$datetime_format = 'y-m-d H:i:s';

// Allowed file extensions for create and rename files
// e.g. 'txt,html,css,js'
\$allowed_file_extensions = '';

// Allowed file extensions for upload files
// e.g. 'gif,png,jpg,html,txt'
// \$allowed_upload_extensions = 'jpg,jpeg,gif,txt,mp4,doc,xls,xlsx,docx,pdf';
\$allowed_upload_extensions = '';

// Favicon path. This can be either a full url to an .PNG image, or a path based on the document root.
// full path, e.g http://example.com/favicon.png
// local path, e.g images/icons/favicon.png
\$favicon_path = 'https://127.0.0.1/favicon.ico';

// Files and folders to excluded from listing
// e.g. array('myfile.html', 'personal-folder', '*.php', ...)
// Files and folders to excluded from listing
\$exclude_items = array(
    'my-folder',
    'secret-files',
    'tinyfilemanger.php',
    '*.php',
    '*.js',
    'file.lst'
);

// Online office Docs Viewer
// Availabe rules are 'google', 'microsoft' or false
// google => View documents using Google Docs Viewer
// microsoft => View documents using Microsoft Web Apps Viewer
// false => disable online doc viewer
\$online_viewer = 'google';

// Sticky Nav bar
// true => enable sticky header
// false => disable sticky header
\$sticky_navbar = true;


// max upload file size MB
\$max_upload_size_bytes = 300;

// Possible rules are 'OFF', 'AND' or 'OR'
// OFF => Don't check connection IP, defaults to OFF
// AND => Connection must be on the whitelist, and not on the blacklist
// OR => Connection must be on the whitelist, or not on the blacklist
\$ip_ruleset = 'OR';

// Should users be notified of their block?
\$ip_silent = true;

// IP-addresses, both ipv4 and ipv6
\$ip_whitelist = array(
    '127.0.0.1',    // local ipv4
    '::1'           // local ipv6
);

// IP-addresses, both ipv4 and ipv6
\$ip_blacklist = array(
    '0.0.0.0',      // non-routable meta ipv4
    '::'            // non-routable meta ipv6
);

?>
"


# TFM仓库
TFM_REPO=https://github.com/prasathmani/tinyfilemanager

NGINX_CONF="server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;   
    root $HOME/file-manager;
    index.php index index.html index.htm index.nginx-debian.html;
    # manual
    server_name YourServer.com;
    
    location ~ \.php?.*$ { 
        # manual Your php-fpm listen port 
        fastcgi_pass   127.0.0.1:9000; 
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name; 
        include        fastcgi_params; 
    }

    ssl_certificate /etc/ssl/YourServer.com.pem;
    ssl_certificate_key /etc/ssl/YourServer.com.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;
    # curl https://ssl-config.mozilla.org/ffdhe2048.txt > /path/to/dhparam
    # ssl_dhparam /path/to/dhparam;
    # intermediate configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    # HSTS (ngx_http_headers_module is required) (63072000 seconds)
    add_header Strict-Transport-Security \"max-age=63072000\" always;
}

"

## 控制台颜色输出
# 红色：警告、重点
# 黄色：警告、一般打印
# 绿色：执行日志
# 蓝色、白色：常规信息
# 颜色colors
CDEF=" \033[0m"                                     # default color
CCIN=" \033[0;36m"                                  # info color
CGSC=" \033[0;32m"                                  # success color
CRER=" \033[0;31m"                                  # error color
CWAR=" \033[0;33m"                                  # warning color
b_CDEF=" \033[1;37m"                                # bold default color
b_CCIN=" \033[1;36m"                                # bold info color
b_CGSC=" \033[1;32m"                                # bold success color
b_CRER=" \033[1;31m"                                # bold error color
b_CWAR=" \033[1;33m"  
# echo like ...  with  flag type  and display message  colors
# -s 绿
# -e 红
# -w 黄
# -i 蓝
prompt () {
  case ${1} in
    "-s"|"--success")
      echo -e "${b_CGSC}${@/-s/}${CDEF}";;          # print success message
    "-x"|"--exec")
      echo -e "Exec：${b_CGSC}${@/-x/}${CDEF}";;          # print exec message
    "-e"|"--error")
      echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
    "-w"|"--warning")
      echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
    "-i"|"--info")
      echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
    "-m"|"--msg")
      echo -e "Info：${b_CCIN}${@/-m/}${CDEF}";;          # print iinfo message
    "-k"|"--kv")  # 三个参数
      echo -e "${b_CCIN} ${2} ${b_CWAR} ${3} ${CDEF}";;          # print success message
    *)
    echo -e "$@"
    ;;
  esac
}

### 预先检查
# 检查是否有root权限，有则退出，提示用户使用普通用户权限。
prompt -i "\n检查权限  ——    Checking for root access...\n"
if [ "$UID" -eq 0 ]; then
    # Error message
    prompt -e "\n [ Error ] -> 请不要使用管理员权限运行 Please DO NOT run as root  \n"
    exit 1
else
    prompt -w "\n——————————  Unit Ready  ——————————\n"
fi

sudo ls > /dev/null
# 是否临时加入sudoer
TEMPORARILY_SUDOER=0
# 临时加入sudoer所使用的语句
TEMPORARILY_SUDOER_STRING="$USER ALL=(ALL)NOPASSWD:ALL"
# 检查是否在sudo组中 0 false 1 true
IS_SUDOER=-1
is_sudoer=-1
IS_SUDO_NOPASSWD=-1
is_sudo_nopasswd=-1
# 检查是否在sudo组
if groups| grep sudo > /dev/null ;then
    # 是sudo组
    IS_SUDOER=1
    is_sudoer="TRUE"
    # 检查是否免密码sudo 括号得注释
    check_var="ALL=(ALL)NOPASSWD:ALL"
    # cat /etc/sudoers
    if sudo cat /etc/sudoers | grep ^$USER | grep $check_var > /dev/null ;then
        # sudo免密码
        IS_SUDO_NOPASSWD=1
        is_sudo_nopasswd="TRUE"
    else
        # sudo要密码
        IS_SUDO_NOPASSWD=0
        is_sudo_nopasswd="FALSE"
    fi
else
    # 不是sudoer
    IS_SUDOER=0
    IS_SUDO_NOPASSWD=0
    is_sudoer="FALSE"
    is_sudo_nopasswd="No a sudoer"
fi

prompt -i "__________________________________________________________"
prompt -k "是否为Sudo组成员：" "$is_sudoer"
prompt -k "Sudo是否免密码：" "$is_sudo_nopasswd"
prompt -i "__________________________________________________________"
echo ""
echo ""
# 如果用户按下Ctrl+c
trap "onSigint" SIGINT

# 程序中断处理方法,包含正常退出该执行的代码
onSigint () {
    prompt -w "捕获到中断信号..."
    onExit 
    exit 1
}

# 正常退出需要执行的
onExit () {
    # 临时加入sudoer，退出时清除
    if [ $TEMPORARILY_SUDOER -eq 1 ] ;then
        prompt -x "Clean temp sudoer no-passwd..."
        # sudo sed -i "s/$TEMPORARILY_SUDOER_STRING/ /g" /etc/sudoers
        # 获取最后一行
        tail_sudo=`sudo tail -n 1 /etc/sudoers`
        if [ "$tail_sudo" = "$TEMPORARILY_SUDOER_STRING" ] > /dev/null ;then
            # 删除最后一行
            sudo sed -i '$d' /etc/sudoers
        else
            # 一般不会出现这个情况吧。。
            prompt -e "WARN: Unknown ERROR.Del $TEMPORARILY_SUDOER_STRING in /etc/sudoers"
            exit 1
        fi
    fi
}
# 中途异常退出脚本要执行的
quitThis () {
    onExit
    exit
}
if [ "$IS_SUDOER" -eq 0 ];then
    prompt -e "Not a sudoer!"
    exit 1
fi
# 如果是sudoer，但没有免密码，临时配置
if [ "$IS_SUDOER" -eq 1 ] && [ "$IS_SUDO_NOPASSWD" -eq 0 ];then
    echo "$TEMPORARILY_SUDOER_STRING" | sudo tee -a /etc/sudoers
    TEMPORARILY_SUDOER=1
fi

##############################################################

# 检查命令
if ! [ -x "$(command -v git)" ]; then
    prompt -e "Git not found! Install git first!"
    quitThis
fi

if ! [ -x "$(command -v getfacl)" ]; then
    prompt -e "ACL not found!"
    sudo apt install acl
    if [ "$?" -eq 0 ]; then
        prompt -e "ACL install failed !"
        quitThis
    fi
fi

# 检查文件夹
if ! [ -d "$TFM_ROOT" ];then
    mkdir -p "$TFM_ROOT"
fi

if ! [ -d "$TFM_ROOT/files" ];then
    mkdir "$TFM_ROOT/files"
fi

if ! [ -d "$TFM_ROOT/files/temp" ];then
    mkdir "$TFM_ROOT/files/temp"
fi

# 安装
cd "$TFM_ROOT"
git clone "$TFM_REPO" repo
cp ./repo/tinyfilemanager.php index.php 
cp ./repo/translation.json .
echo "$TFM_CONFIG" > config.php

# 设置权限
sudo chown www-data index.php 
setfacl -m u:www-data:rx config.php 
sudo chown www-data files
sudo chown www-data files/temp

sudo chgrp www-data index.php 
sudo chgrp www-data files
sudo chgrp www-data files/temp

sudo chown www-data index.php 
sudo chown www-data index.php 

prompt -w "If user www-data still cannot write, try acl(e.g: setfacl -m u:www-data:rwx files)"

prompt -i "Check manully and setting up reverse proxy by yourself."
prompt -i "========================================================"
prompt -s "For Nginx:"
echo "$NGINX_CONF"
prompt -i "========================================================"
onExit





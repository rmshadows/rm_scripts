#!/bin/bash
# setupNginxForFmgr.sh —— fmgr 交互式部署 + 卸载
#
# 部署（默认）：
#   1. 安装 nginx + php-fpm + 必要扩展（已装则跳过），自动检测 PHP-FPM socket（不写死版本）
#   2. 交互询问：目标父目录、nginx 配置方式、是否替换 site 的 root、首页处理
#   3. 同步 fmgr 本体到目标父目录/fmgr（MoveToParent 仅在 root 指向 FMGR_PARENT 时才拷）
#   4. snippet 模式：仅写 snippet + 取消注释已有的注释 include 行（不主动插入）
#      standalone 模式：拷贝 http 作独立 site，自动替换 root 与 PHP socket
#   5. 检测目标 site 是否有 PHP 处理 location（fmgr 是 PHP 应用），缺失则打印需手动添加的内容
#   6. 按选择处理首页（跳转页 / 404 / 不处理）
#   7. 设置文件权限：整体归当前用户，上传目录归 www-data 组且可读写
#   8. nginx -t 校验，通过则 reload（不启动 php-fpm / nginx 服务，由用户决定）
#
# 卸载（--uninstall / -u）：
#   1. 交互询问：是否保留上传文件
#   2. 注释 include 行 / 禁用独立 site
#   3. 删除 snippet
#   4. 删除 fmgr 目录（按选择保留上传备份）
#   5. nginx -t 校验
#   6. 不卸载 nginx / php-fpm 系统包（用户可能另有用途）
#
# 用法：
#   ./setupNginxForFmgr.sh                       # 交互式部署
#   ./setupNginxForFmgr.sh --uninstall          # 交互式卸载
#   ./setupNginxForFmgr.sh --uninstall --purge  # 强卸（不询问，全删）
#   ./setupNginxForFmgr.sh --yes                # 非交互，全用配置区默认值
#   ./setupNginxForFmgr.sh --help
#
# 例：把配置区 FMGR_PARENT 改成 /srv/www，加 --yes 即可非交互部署到 /srv/www/fmgr

set -euo pipefail

############################
# 配置区（按需修改，作为交互默认值）
############################
# fmgr 部署到的父目录（fmgr 本体在 $FMGR_PARENT/fmgr）
FMGR_PARENT="/home/HTML"
# nginx snippet 路径
NGINX_SNIPPET="/etc/nginx/snippets/fmgr.conf"
# web server 进程组（用于上传目录写权限；不知道就留 www-data）
WWW_GROUP="www-data"
# 首页处理：jump=跳转页, 404=404页, none=不处理
HOMEPAGE_MODE="jump"
# nginx 配置方式：snippet=加 include 到现有 site, standalone=用仓库 http 作为独立 site, skip=跳过
NGINX_MODE="snippet"
# 非交互模式（全部使用默认值，不询问）
ASSUME_YES=0

############################
# 自动推导路径（一般无需改）
############################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FMGR_SRC_REPO="$(dirname "$SCRIPT_DIR")"          # 仓库里的 fmgr文件传输/ 目录
FMGR_DST="$FMGR_PARENT/fmgr"
SNIPPET_SRC="$SCRIPT_DIR/fmgr-snippet.conf"
HTTP_SRC="$SCRIPT_DIR/http"
STANDALONE_SITE_AVAIL="/etc/nginx/sites-available/fmgr"
STANDALONE_SITE_EN="/etc/nginx/sites-enabled/fmgr"
CURRENT_USER="${SUDO_USER:-$USER}"

# 颜色输出（无 tty 退化为纯文本）
if [ -t 1 ]; then
    C_R=$'\033[31m'; C_Y=$'\033[33m'; C_G=$'\033[32m'; C_M=$'\033[36m'; C_DIM=$'\033[2m'; C_0=$'\033[0m'
else
    C_R=''; C_Y=''; C_G=''; C_M=''; C_DIM=''; C_0=''
fi
log()  { printf '%b\n' "${C_M}[$(date +%H:%M:%S)] $*${C_0}"; }
ok()   { printf '%b\n' "${C_G}[$(date +%H:%M:%S)] ✓ $*${C_0}"; }
warn() { printf '%b\n' "${C_Y}[$(date +%H:%M:%S)] ! $*${C_0}" >&2; }
err()  { printf '%b\n' "${C_R}[$(date +%H:%M:%S)] ✗ $*${C_0}" >&2; }

############################
# 交互函数
############################
# ask "提示" "默认值" var_name  —— 把答案写入 var_name（空回车=默认值）
ask() {
    local prompt="$1" default="$2" var_name="$3" answer=""
    if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then
        eval "$var_name=\"\$default\""
        printf '%b%s%s %b[%s]%b %s\n' "$C_M" "$prompt" "$C_0" "$C_DIM" "$default" "$C_0" "(使用默认)"
        return
    fi
    printf '%b%s%s %b[%s]%b: ' "$C_M" "$prompt" "$C_0" "$C_DIM" "$default" "$C_0"
    read -r answer || true
    eval "$var_name=\"\${answer:-\$default}\""
}

# ask_yn "提示" y|n  —— 返回 0=yes, 1=no
ask_yn() {
    local prompt="$1" default="${2:-y}" hint answer=""
    [ "$default" = "y" ] && hint="[Y/n]" || hint="[y/N]"
    if [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then
        printf '%b%s%s %b%s%b %s\n' "$C_M" "$prompt" "$C_0" "$C_DIM" "$hint" "$C_0" "(使用默认)"
        [ "$default" = "y" ] && return 0 || return 1
    fi
    printf '%b%s%s %b%s%b: ' "$C_M" "$prompt" "$C_0" "$C_DIM" "$hint" "$C_0"
    read -r answer || true
    answer="${answer:-$default}"
    case "${answer,,}" in y|yes) return 0 ;; *) return 1 ;; esac
}

# ask_choice "提示" "默认序号" "选项1" "选项2" ...  —— 把选项文本写入全局 $CHOICE
declare -g CHOICE=""
ask_choice() {
    local prompt="$1" default_idx="$2"; shift 2
    local options=("$@") i=1
    printf '%b%s%s\n' "$C_M" "$prompt" "$C_0"
    for opt in "${options[@]}"; do
        if [ "$i" = "$default_idx" ]; then
            printf '  %b%d) %s%s %b(默认)%b\n' "$C_G" "$i" "$opt" "$C_0" "$C_DIM" "$C_0"
        else
            printf '  %d) %s\n' "$i" "$opt"
        fi
        i=$((i+1))
    done
    local idx
    ask "输入序号" "$default_idx" idx
    if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#options[@]}" ]; then
        CHOICE="${options[$((idx-1))]}"
        ok "选择：$CHOICE"
    else
        warn "序号无效，使用默认"
        CHOICE="${options[$((default_idx-1))]}"
    fi
}

# 检测当前 PHP-FPM socket
detect_php_socket() {
    local sock
    sock=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -1 || true)
    if [ -n "$sock" ]; then
        echo "unix:$sock"
    else
        echo "unix:/run/php/php-fpm.sock"
    fi
}

# nginx 正在运行就 reload
reload_nginx_if_running() {
    if [ ! -x "$(command -v nginx)" ]; then return 0; fi
    if systemctl is-active --quiet nginx 2>/dev/null; then
        log "nginx 正在运行，自动 reload..."
        if systemctl reload nginx; then ok "nginx 已 reload"
        else warn "nginx reload 失败，请手动检查"; fi
    else
        warn "nginx 未运行，未 reload。如需启用：sudo systemctl start php*-fpm nginx"
    fi
}

# 列出 sites-enabled 下的 site 文件（去掉路径）
list_sites() {
    local d=/etc/nginx/sites-enabled
    [ -d "$d" ] || return 0
    local f
    for f in "$d"/*; do
        [ -f "$f" ] || continue
        basename "$f"
    done
}

############################
# do_install —— 部署
############################
do_install() {
    ############################
    # 0. 前置检查
    ############################
    [ -f "$SNIPPET_SRC" ]   || { err "找不到 snippet 模板：$SNIPPET_SRC"; exit 1; }
    [ -d "$FMGR_SRC_REPO" ] || { err "找不到 fmgr 源仓库：$FMGR_SRC_REPO"; exit 1; }
    command -v apt >/dev/null 2>&1 || { err "非 Debian/Ubuntu，请手动安装 nginx + php-fpm。"; exit 1; }

    ############################
    # 1. 交互询问目标目录
    ############################
    log "==== fmgr 部署配置 ===="
    ask "fmgr 部署到哪个父目录" "$FMGR_PARENT" FMGR_PARENT
    FMGR_DST="$FMGR_PARENT/fmgr"
    ok "目标：$FMGR_DST"

    ############################
    # 2. 安装 nginx + php-fpm + 扩展
    ############################
    if ! command -v nginx >/dev/null 2>&1; then
        log "nginx 未安装，开始安装..."
        apt update
        DEBIAN_FRONTEND=noninteractive apt install -y nginx
    else ok "nginx 已安装"; fi

    if ! command -v php-fpm >/dev/null 2>&1 && ! ls /usr/sbin/php*-fpm >/dev/null 2>&1; then
        log "php-fpm 未安装，开始安装..."
        DEBIAN_FRONTEND=noninteractive apt install -y php-fpm
    else ok "php-fpm 已安装"; fi

    log "确保 PHP 扩展齐全：mbstring zip xml gd"
    DEBIAN_FRONTEND=noninteractive apt install -y php-mbstring php-zip php-xml php-gd || \
        warn "部分 PHP 扩展安装失败，可能影响功能"

    # 检测 PHP-FPM socket（不写死版本）
    local php_sock
    php_sock=$(detect_php_socket)
    ok "PHP-FPM socket: $php_sock"

    ############################
    # 3. 同步 fmgr 本体（仅 fmgr 目录，不动父目录其他文件；MoveToParent 稍后按需拷）
    ############################
    log "部署 fmgr 本体到 $FMGR_DST ..."
    mkdir -p "$FMGR_PARENT" "$FMGR_DST"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a \
            --exclude 'NginxSetup' --exclude '.git' --exclude '.idea' \
            "$FMGR_SRC_REPO/" "$FMGR_DST/"
    else
        cp -a "$FMGR_SRC_REPO/." "$FMGR_DST/"
        rm -rf "$FMGR_DST/NginxSetup" "$FMGR_DST/.git" "$FMGR_DST/.idea" 2>/dev/null || true
    fi
    ok "fmgr 本体已就位"

    ############################
    # 4. 询问 nginx 配置方式
    ############################
    echo ""
    ask_choice "请选择 nginx 配置方式：" 1 \
        "snippet: 仅写 snippet，手动 include 到现有 site（最安全，不改原配置）" \
        "standalone: 用仓库 http 作为独立 site（开箱即用，自动替换 root 与 PHP socket）" \
        "skip: 跳过 nginx 配置"
    case "$CHOICE" in
        snippet*)    NGINX_MODE="snippet" ;;
        standalone*) NGINX_MODE="standalone" ;;
        skip*)       NGINX_MODE="skip" ;;
    esac

    # replace_root=1 表示 site 的 root 已指向 $FMGR_PARENT，此时 MoveToParent 的 jumpindex/404/favicon 才有意义
    local replace_root=0
    local target_site=""

    case "$NGINX_MODE" in
        snippet)
            # 写 snippet（同时替换 root 与 PHP socket，PHP 处理已写在 snippet 里）
            # 若目标 site 已有自己的 PHP location，则用 sed 删掉 snippet 里的 PHP 块（避免 duplicate location）
            mkdir -p /etc/nginx/snippets

            # 先准备一个变量：是否需要去掉 PHP 块（默认不需要）
            local strip_php=0

            # 列出现有 site 让用户选
            echo ""
            local sites=()
            local site
            while IFS= read -r site; do
                [ -n "$site" ] && sites+=("$site")
            done < <(list_sites)
            if [ "${#sites[@]}" -eq 0 ]; then
                warn "sites-enabled 下没有 site，请稍后手动在某 server{} 内加："
                warn "    include $NGINX_SNIPPET;  （含 PHP 处理，无需再单独配）"
            else
                echo "当前 sites-enabled："
                ask_choice "选择要配置的 site" 1 "${sites[@]}"
                target_site="/etc/nginx/sites-enabled/$CHOICE"

                # 4.1 检测已有 PHP 处理 location
                if grep -qE "^[[:space:]]*location[[:space:]]+~[^{]*\\.php" "$target_site" 2>/dev/null; then
                    warn "$target_site 已有自己的 PHP 处理 location"
                    warn "  若 snippet 也带 PHP 块会触发 nginx -t 'duplicate location' 错误"
                    if ask_yn "是否让 snippet 不带 PHP 块（保留你原有的 PHP 配置）？" "y"; then
                        strip_php=1
                        ok "snippet 将不带 PHP 块，沿用 $target_site 原有 PHP 配置"
                    else
                        warn "保留 snippet 的 PHP 块——请手动删掉 $target_site 里原有的 PHP location"
                    fi
                else
                    ok "$target_site 无 PHP 处理 location，snippet 含 PHP 块（fastcgi_pass=$php_sock）"
                fi
            fi

            # 实际写入 snippet
            if [ "$strip_php" -eq 1 ]; then
                sed \
                    -e '/# BEGIN_FMGR_PHP/,/# END_FMGR_PHP/d' \
                    -e "s|__FMGR_PARENT__|$FMGR_PARENT|g" \
                    "$SNIPPET_SRC" > "$NGINX_SNIPPET"
                ok "已写入 $NGINX_SNIPPET（不含 PHP 块，沿用目标 site 原有 PHP 配置）"
            else
                sed \
                    -e "s|__FMGR_PARENT__|$FMGR_PARENT|g" \
                    -e "s|__PHP_SOCK__|$php_sock|g" \
                    "$SNIPPET_SRC" > "$NGINX_SNIPPET"
                ok "已写入 $NGINX_SNIPPET（含 PHP 块，fastcgi_pass=$php_sock）"
            fi
            chmod 0644 "$NGINX_SNIPPET"

            # 4.2 询问是否替换 root（不替换则 MoveToParent 拷过去也读不到）
            if [ -n "$target_site" ]; then
                local cur_root
                cur_root=$(grep -oE "^[[:space:]]*root[[:space:]]+[^;]+;" "$target_site" 2>/dev/null | head -1 | sed 's/^[[:space:]]*root[[:space:]]*//;s/;$//')
                log "$target_site 当前 root: ${cur_root:-（未检测到）}"
                if [ -n "$cur_root" ] && [ "$cur_root" != "$FMGR_PARENT" ]; then
                    if ask_yn "是否把 $target_site 的 root 替换为 $FMGR_PARENT？（替换后 MoveToParent 的 jumpindex/404/favicon 才生效）" "n"; then
                        # 只替换第一个 root 指令（server 块顶层）
                        sed -i -E "0,/^[[:space:]]*root[[:space:]]+[^;]+;/{s|^[[:space:]]*root[[:space:]]+[^;]+;|    root $FMGR_PARENT;|}" "$target_site"
                        ok "已替换 $target_site 的 root → $FMGR_PARENT"
                        replace_root=1
                    else
                        ok "保留原 root，仅 fmgr 子路径可用，MoveToParent 不拷贝"
                    fi
                fi

                # 4.3 include 行：仅取消注释已有的注释 include 行，不主动插入
                if grep -qE "^[[:space:]]*include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;" "$target_site" 2>/dev/null; then
                    ok "$target_site 已有 include 行，无需处理"
                elif grep -qE "^[[:space:]]*#[[:space:]]*include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;" "$target_site" 2>/dev/null; then
                    if ask_yn "检测到 $target_site 有被注释的 include 行，是否取消注释？" "y"; then
                        sed -i -E "s|^[[:space:]]*#[[:space:]]*(include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;)|    \1|" "$target_site"
                        ok "已取消注释 $target_site 里的 include 行"
                    else
                        warn "请在 $target_site 的 server{} 内手动加："
                        warn "    include $NGINX_SNIPPET;"
                    fi
                else
                    warn "请在 $target_site 的 server{} 内手动加："
                    warn "    include $NGINX_SNIPPET;"
                fi
            fi
            ;;

        standalone)
            # 拷贝 http 到 sites-available，替换 root 和 PHP socket（不写死版本）
            mkdir -p /etc/nginx/sites-available
            sed \
                -e "s|root /home/HTML;|root $FMGR_PARENT;|" \
                -e "s|unix:/run/php/php[0-9.]*-fpm.sock|$php_sock|g" \
                "$HTTP_SRC" > "$STANDALONE_SITE_AVAIL"
            # 注释掉 BEGIN_DENY_DYNAMIC 段（避免拦截 /fmgr/*.php）
            sed -i '/# BEGIN_DENY_DYNAMIC/,/# END_DENY_DYNAMIC/s/^/# /' "$STANDALONE_SITE_AVAIL"
            chmod 0644 "$STANDALONE_SITE_AVAIL"
            ln -sf "$STANDALONE_SITE_AVAIL" "$STANDALONE_SITE_EN"
            ok "已启用独立 site：$STANDALONE_SITE_EN"
            warn "注意：仓库 http 里 listen 80 default_server，若机器上已有 default_server 会冲突"
            warn "      nginx -t 报错时，请编辑 $STANDALONE_SITE_AVAIL 去掉 default_server"
            replace_root=1  # standalone 模式 root 必然是 $FMGR_PARENT
            ;;

        skip)
            warn "跳过 nginx 配置，请稍后手动处理"
            ;;
    esac

    ############################
    # 5. 处理 MoveToParent + 首页（仅当 root 指向 $FMGR_PARENT 时才有意义）
    ############################
    if [ "$replace_root" -eq 1 ] && [ -d "$FMGR_SRC_REPO/MoveToParent" ]; then
        log "处理 MoveToParent → $FMGR_PARENT/（不覆盖已有文件）"
        cp -an "$FMGR_SRC_REPO/MoveToParent/." "$FMGR_PARENT/" 2>/dev/null \
            || cp -a "$FMGR_SRC_REPO/MoveToParent/." "$FMGR_PARENT/"

        # 询问首页处理
        local has_index="无"
        [ -f "$FMGR_PARENT/index.html" ] && has_index="有"
        log "当前 $FMGR_PARENT/index.html: $has_index"
        echo ""
        ask_choice "请选择首页处理方式：" 1 \
            "jump: 跳转页（用 jumpindex.html 作为 index.html，覆盖已有）" \
            "404: 404页（用 404index.html 作为 index.html，覆盖已有）" \
            "none: 不处理（保留已有首页或留空）"
        case "$CHOICE" in
            jump*) HOMEPAGE_MODE="jump" ;;
            404*)  HOMEPAGE_MODE="404" ;;
            none*) HOMEPAGE_MODE="none" ;;
        esac
        case "$HOMEPAGE_MODE" in
            jump)
                if [ -f "$FMGR_PARENT/jumpindex.html" ]; then
                    cp "$FMGR_PARENT/jumpindex.html" "$FMGR_PARENT/index.html"
                    ok "首页设为跳转页"
                else warn "找不到 jumpindex.html，跳过"; fi
                ;;
            404)
                if [ -f "$FMGR_PARENT/404index.html" ]; then
                    cp "$FMGR_PARENT/404index.html" "$FMGR_PARENT/index.html"
                    ok "首页设为 404 页"
                else warn "找不到 404index.html，跳过"; fi
                ;;
            none) ok "不处理首页" ;;
        esac
    else
        ok "未替换 root，跳过 MoveToParent 与首页处理"
    fi

    ############################
    # 6. 设置权限
    ############################
    log "设置文件权限..."
    chown -R "$CURRENT_USER:$CURRENT_USER" "$FMGR_PARENT"

    if ! getent group "$WWW_GROUP" >/dev/null 2>&1; then
        warn "未找到组 $WWW_GROUP，上传目录组改设为 $CURRENT_USER"
        WWW_GROUP="$CURRENT_USER"
    fi

    local UPLOAD_DIR="$FMGR_DST/files"
    local TEMP_DIR="$FMGR_DST/files/tempUpload"
    mkdir -p "$UPLOAD_DIR" "$TEMP_DIR"
    chgrp -R "$WWW_GROUP" "$UPLOAD_DIR" "$TEMP_DIR" 2>/dev/null || true
    chmod -R ug+rwx "$UPLOAD_DIR"
    chmod g+s "$UPLOAD_DIR" "$TEMP_DIR" 2>/dev/null || true
    find "$FMGR_DST" -type f -name '*.php' -exec chmod 0640 {} \; 2>/dev/null || true
    ok "权限已设置：fmgr 整体 $CURRENT_USER:$CURRENT_USER；上传目录组 $WWW_GROUP"

    ############################
    # 7. nginx 配置校验
    ############################
    if command -v nginx >/dev/null 2>&1; then
        log "nginx -t 配置校验..."
        if nginx -t 2>&1; then
            ok "nginx 配置校验通过"
            reload_nginx_if_running
        else
            err "nginx 配置校验失败，请检查以上错误"
            exit 1
        fi
    fi

    ############################
    # 8. 汇总输出
    ############################
    cat <<EOF

==============================================
✓ fmgr 部署完成（开箱即用）

  fmgr 目录      : $FMGR_DST
  Web 访问入口   : http://<本机>/  或  /x  或  /fmgr/
  上传目录(可写) : $UPLOAD_DIR   (组: $WWW_GROUP)
  PHP-FPM socket: $php_sock
EOF
    case "$NGINX_MODE" in
        snippet)
            echo "  Nginx 配置   : snippet $NGINX_SNIPPET"
            [ -n "$target_site" ] && echo "  目标 site    : $target_site"
            ;;
        standalone) echo "  Nginx 配置   : 独立 site $STANDALONE_SITE_EN" ;;
        skip)      echo "  Nginx 配置   : 未配置（需手动）" ;;
    esac
    if [ "$replace_root" -eq 1 ]; then
        case "$HOMEPAGE_MODE" in
            jump) echo "  首页          : 跳转页" ;;
            404)  echo "  首页          : 404 页" ;;
            none) echo "  首页          : 不处理" ;;
        esac
    fi
    cat <<EOF

  下一步：启动 php-fpm 和 nginx（如未启动）：
    sudo systemctl start php*-fpm nginx

  卸载：  ./setupNginxForFmgr.sh --uninstall
  强卸：  ./setupNginxForFmgr.sh --uninstall --purge

  默认账号见 fmgr 源仓库 README.md（admin / user / 123456 等）
==============================================
EOF
}

############################
# do_uninstall —— 卸载
############################
do_uninstall() {
    log "==== fmgr 卸载 ===="
    ask "要卸载的 fmgr 父目录" "$FMGR_PARENT" FMGR_PARENT
    FMGR_DST="$FMGR_PARENT/fmgr"

    local keep_uploads=1
    if [ "$PURGE" -eq 0 ]; then
        if ask_yn "保留上传文件到备份目录（fmgr.files.bak）？" "y"; then
            keep_uploads=1
        else
            keep_uploads=0
            if ! ask_yn "确认强删全部（含上传文件）？" "n"; then
                warn "已取消，退出"
                exit 0
            fi
        fi
    else
        keep_uploads=0
    fi

    ############################
    # 1. 注释 site-enabled 里的 include 行 / 禁用独立 site
    ############################
    local SITES_DIR=/etc/nginx/sites-enabled
    local TOUCHED_FILES=""
    if [ -d "$SITES_DIR" ]; then
        for f in "$SITES_DIR"/*; do
            [ -f "$f" ] || continue
            if grep -qE "^[[:space:]]*include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;" "$f" 2>/dev/null; then
                sed -i -E "s|^([[:space:]]*)include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;|\1# include ${NGINX_SNIPPET};|" "$f"
                TOUCHED_FILES="$TOUCHED_FILES $f"
                ok "已注释 $f 里的 include 行"
            fi
        done
    fi
    # 禁用独立 site
    if [ -L "$STANDALONE_SITE_EN" ] || [ -f "$STANDALONE_SITE_EN" ]; then
        rm -f "$STANDALONE_SITE_EN"
        ok "已禁用独立 site：$STANDALONE_SITE_EN"
    fi
    if [ -f "$STANDALONE_SITE_AVAIL" ]; then
        rm -f "$STANDALONE_SITE_AVAIL"
        ok "已删除 $STANDALONE_SITE_AVAIL"
    fi

    ############################
    # 2. 删除 snippet
    ############################
    if [ -f "$NGINX_SNIPPET" ]; then
        rm -f "$NGINX_SNIPPET"
        ok "已删除 $NGINX_SNIPPET"
    else
        warn "snippet 不存在：$NGINX_SNIPPET"
    fi

    ############################
    # 3. 处理 fmgr 文件
    ############################
    if [ -d "$FMGR_DST" ]; then
        local UPLOAD_DIR="$FMGR_DST/files"
        local BACKUP_DIR="${FMGR_DST}.files.bak"

        if [ "$keep_uploads" -eq 1 ] && [ -d "$UPLOAD_DIR" ]; then
            if [ -d "$BACKUP_DIR" ]; then
                warn "备份目录已存在：$BACKUP_DIR，合并覆盖"
                cp -a "$UPLOAD_DIR/." "$BACKUP_DIR/" 2>/dev/null || true
            else
                mv "$UPLOAD_DIR" "$BACKUP_DIR"
                ok "已保留上传文件到 $BACKUP_DIR"
            fi
        fi
        rm -rf "$FMGR_DST"
        ok "已删除 fmgr 目录：$FMGR_DST"
    else
        warn "fmgr 目录不存在：$FMGR_DST"
    fi

    ############################
    # 4. nginx 配置校验
    ############################
    if command -v nginx >/dev/null 2>&1; then
        log "nginx -t 配置校验..."
        if nginx -t 2>&1; then
            ok "nginx 配置校验通过"
            reload_nginx_if_running
        else
            err "nginx 配置校验失败，请检查以上错误"
            [ -n "$TOUCHED_FILES" ] && err "可手动恢复：取消注释 $TOUCHED_FILES 里的 include 行"
            exit 1
        fi
    fi

    ############################
    # 5. 汇总输出
    ############################
    cat <<EOF

==============================================
✓ fmgr 卸载完成

  删除 snippet  : $NGINX_SNIPPET
  删除 fmgr 目录: $FMGR_DST
EOF
    [ -n "$TOUCHED_FILES" ] && echo "  已注释 include: $TOUCHED_FILES"
    [ "$keep_uploads" -eq 1 ] && [ -d "${FMGR_DST}.files.bak" ] && \
        echo "  上传文件备份  : ${FMGR_DST}.files.bak"
    cat <<EOF

  注意：未卸载 nginx / php-fpm 系统包（用户可能另有用途）
  如需彻底卸载：
    sudo apt purge -y nginx php*-fpm php-mbstring php-zip php-xml php-gd
    sudo apt autoremove -y
==============================================
EOF
}

############################
# 命令行参数解析与分发
############################
ACTION="install"
PURGE=0
for arg in "$@"; do
    case "$arg" in
        --uninstall|-u) ACTION="uninstall" ;;
        --purge)        PURGE=1 ;;
        --yes|-y)       ASSUME_YES=1 ;;
        --help|-h)
            sed -n '2,35p' "$0"
            exit 0 ;;
        *) err "未知参数: $arg"; exit 2 ;;
    esac
done

# 写 /etc/nginx 需要 root；非 root 自动 sudo 重跑
if [ "$(id -u)" -ne 0 ]; then
    log "需要 root 权限，重新以 sudo 运行..."
    exec sudo -E bash "$0" "$@"
fi

if [ "$ACTION" = "uninstall" ]; then
    do_uninstall
else
    do_install
fi

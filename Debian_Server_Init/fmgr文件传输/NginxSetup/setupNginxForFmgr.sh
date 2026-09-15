#!/bin/bash
# setupNginxForFmgr.sh —— fmgr 部署 / 卸载（编辑源：仓库根 fmgr文件传输/；打包后在各 Init 内）
#
# 交互（Server application / 手工）：
#   ./setupNginxForFmgr.sh
#
# 非交互（GNOME Init 等）：
#   FMGR_PARENT=/home/HTML TARGET_SITE=/etc/nginx/sites-available/html.conf \
#     ./setupNginxForFmgr.sh --batch
#   --batch = 全用环境变量/默认值，不提问；不自动插入 PHP；不启用 standalone
#
# 环境变量：
#   FMGR_PARENT   父目录（默认 /home/HTML）
#   NGINX_MODE    snippet|standalone|skip（--batch 时必看此值，默认 snippet）
#   TARGET_SITE   snippet 要改的 site 文件（如 html.conf）；--batch 强烈建议设置
#   HOMEPAGE_MODE jump|404|none（默认 jump）
#
# 例：FMGR_PARENT=/srv/www ./setupNginxForFmgr.sh

set -euo pipefail

############################
# 配置区（交互默认值 / --batch 生效值）
############################
FMGR_PARENT="${FMGR_PARENT:-/home/HTML}"
NGINX_SNIPPET="/etc/nginx/snippets/fmgr.conf"
WWW_GROUP="www-data"
HOMEPAGE_MODE="${HOMEPAGE_MODE:-jump}"
NGINX_MODE="${NGINX_MODE:-snippet}"
TARGET_SITE="${TARGET_SITE:-}"
ASSUME_YES=0
BATCH=0

############################
# 路径
############################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FMGR_SRC_REPO="$(dirname "$SCRIPT_DIR")"
FMGR_DST="$FMGR_PARENT/fmgr"
SNIPPET_SRC="$SCRIPT_DIR/fmgr-snippet.conf"
SITE_SRC="$SCRIPT_DIR/fmgr_sites"
STANDALONE_SITE_AVAIL="/etc/nginx/sites-available/fmgr_sites"
STANDALONE_SITE_EN="/etc/nginx/sites-enabled/fmgr_sites"
CURRENT_USER="${SUDO_USER:-$USER}"

if [ -t 1 ]; then
    C_R=$'\033[31m'; C_Y=$'\033[33m'; C_G=$'\033[32m'; C_M=$'\033[36m'; C_DIM=$'\033[2m'; C_0=$'\033[0m'
else
    C_R=''; C_Y=''; C_G=''; C_M=''; C_DIM=''; C_0=''
fi
log()  { printf '%b\n' "${C_M}[$(date +%H:%M:%S)] $*${C_0}"; }
ok()   { printf '%b\n' "${C_G}[$(date +%H:%M:%S)] ✓ $*${C_0}"; }
warn() { printf '%b\n' "${C_Y}[$(date +%H:%M:%S)] ! $*${C_0}" >&2; }
err()  { printf '%b\n' "${C_R}[$(date +%H:%M:%S)] ✗ $*${C_0}" >&2; }

ask() {
    local prompt="$1" default="$2" var_name="$3" answer=""
    # --batch / --yes / 非 tty：绝不 read
    if [ "${BATCH:-0}" -eq 1 ] || [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then
        eval "$var_name=\"\$default\""
        printf '%b%s%s %b[%s]%b %s\n' "$C_M" "$prompt" "$C_0" "$C_DIM" "$default" "$C_0" "(使用默认)"
        return
    fi
    printf '%b%s%s %b[%s]%b: ' "$C_M" "$prompt" "$C_0" "$C_DIM" "$default" "$C_0"
    read -r answer || true
    eval "$var_name=\"\${answer:-\$default}\""
}

ask_yn() {
    local prompt="$1" default="${2:-y}" hint answer=""
    [ "$default" = "y" ] && hint="[Y/n]" || hint="[y/N]"
    if [ "${BATCH:-0}" -eq 1 ] || [ "$ASSUME_YES" -eq 1 ] || [ ! -t 0 ]; then
        printf '%b%s%s %b%s%b %s\n' "$C_M" "$prompt" "$C_0" "$C_DIM" "$hint" "$C_0" "(使用默认)"
        [ "$default" = "y" ] && return 0 || return 1
    fi
    printf '%b%s%s %b%s%b: ' "$C_M" "$prompt" "$C_0" "$C_DIM" "$hint" "$C_0"
    read -r answer || true
    answer="${answer:-$default}"
    case "${answer,,}" in y|yes) return 0 ;; *) return 1 ;; esac
}

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

detect_php_socket() {
    local sock listen
    sock=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -1 || true)
    if [ -n "$sock" ]; then
        echo "unix:$sock"
        return
    fi
    # 服务未启动时 sock 不存在，从 pool 配置读
    listen=$(grep -hE '^listen[[:space:]]*=' /etc/php/*/fpm/pool.d/www.conf 2>/dev/null | head -1 | sed -E 's/^listen[[:space:]]*=[[:space:]]*//')
    if [[ "$listen" == /*.sock ]]; then
        echo "unix:$listen"
        return
    fi
    if [[ "$listen" == /* ]]; then
        echo "unix:$listen"
        return
    fi
    if [[ "$listen" =~ ^[0-9.]+:[0-9]+$ ]] || [[ "$listen" =~ ^[0-9]+$ ]]; then
        echo "127.0.0.1:${listen##*:}"
        return
    fi
    echo "unix:/run/php/php-fpm.sock"
}

reload_nginx_if_running() {
    command -v nginx >/dev/null 2>&1 || return 0
    if systemctl is-active --quiet nginx 2>/dev/null; then
        log "nginx 正在运行，reload..."
        if systemctl reload nginx; then ok "nginx 已 reload"
        else warn "nginx reload 失败，请手动检查"; fi
    else
        warn "nginx 未运行。需要时：sudo systemctl start php*-fpm nginx"
    fi
}

list_sites() {
    local d=/etc/nginx/sites-enabled
    [ -d "$d" ] || return 0
    local f
    for f in "$d"/*; do
        [ -e "$f" ] || continue
        basename "$f"
    done
}

# 找出 sites-enabled 里 listen 80 的配置（不含即将启用的 fmgr_sites）
list_port80_sites() {
    local d=/etc/nginx/sites-enabled f real
    [ -d "$d" ] || return 0
    for f in "$d"/*; do
        [ -e "$f" ] || continue
        [ "$(basename "$f")" = "fmgr_sites" ] && continue
        real="$f"
        [ -L "$f" ] && real=$(readlink -f "$f" || echo "$f")
        if grep -E '^[[:space:]]*listen[[:space:]]+' "$real" 2>/dev/null | grep -qE '(^|[[:space:]:])80([[:space:];]|$)'; then
            basename "$f"
        fi
    done
}

# 目标 site「已有可用 PHP」的判定（从严：宁可误判为有，也不误插）
site_has_php() {
    local f="$1"
    # 活跃的 php location（含 ~*）
    grep -qE '^[[:space:]]*location[[:space:]]+~?\*?[[:space:]]*[^{]*\.php' "$f" 2>/dev/null && return 0
    # Debian 常见 include
    grep -qE '^[[:space:]]*include[[:space:]]+.*fastcgi-php\.conf' "$f" 2>/dev/null && return 0
    # 已有本脚本插入块
    grep -q '# BEGIN_FMGR_ENSURE_PHP' "$f" 2>/dev/null && return 0
    return 1
}

# 文件是否「简单到可以自动插 PHP」（从严）
site_safe_for_php_insert() {
    local f="$1"
    local n_server
    [ -f "$f" ] || return 1
    # 恰好一个未注释的 server {
    n_server=$(grep -cE '^[[:space:]]*server[[:space:]]*\{' "$f" 2>/dev/null || true)
    n_server=${n_server:-0}
    [ "$n_server" = "1" ] || return 1
    # 已有任何 .php 相关 location（含注释掉的）→ 不自动动，避免和用户旧配置打架
    if grep -qE 'location[[:space:]]+~?\*?[[:space:]]*[^{]*\.php' "$f" 2>/dev/null; then
        return 1
    fi
    # 已有 fastcgi_pass → 复杂站，不插
    if grep -qE '^[[:space:]]*fastcgi_pass[[:space:]]' "$f" 2>/dev/null; then
        return 1
    fi
    return 0
}

print_php_block_help() {
    local site="$1" sock="$2"
    cat <<EOF

======= 请人工检查 / 按需粘贴 =======
文件: $site
fmgr 的 snippet **不含 PHP**。该 server 必须已有：

    location ~ \\.php\$ {
        include fastcgi.conf;
        fastcgi_pass $sock;
        fastcgi_index index.php;
    }

若自动插入，块会带标记 # BEGIN/END_FMGR_ENSURE_PHP（卸载只删这块）。
插入后务必：
  1) sudo nginx -t
  2) 打开 http://<主机>/fmgr/index.php 看是否进登录页
  3) 确认没有和原站其它 location 冲突
====================================
EOF
}

# 仅在「确认没有 PHP + 配置足够简单」时才允许自动插入；默认回答 N
ensure_site_php() {
    local site="$1"
    local sock="$2"

    if site_has_php "$site"; then
        ok "$site 已检测到 PHP 处理，不修改（snippet 不含 PHP）"
        warn "【必查】请人工打开 $site，确认 location ~ \\.php\$（或 fastcgi-php）能处理 /fmgr/*.php"
        warn "【必查】确认有：include /etc/nginx/snippets/fmgr.conf;"
        return 0
    fi

    warn "$site 未检测到可用的 PHP location"
    print_php_block_help "$site" "$sock"

    if ! site_safe_for_php_insert "$site"; then
        err "配置偏复杂或多 server / 已有 php·fastcgi 痕迹 → **拒绝自动插入**，请手动加 PHP 块"
        return 1
    fi

    # 非交互 --yes：绝不自动改 site 的 PHP
    if [ "$ASSUME_YES" -eq 1 ]; then
        err "--yes 模式不自动插入 PHP。请手动编辑 $site 后重跑或自行 reload"
        return 1
    fi

    # 默认 N：必须显式同意
    if ! ask_yn "站点很简单且无 PHP，是否自动插入带标记的 PHP 块？（默认否）" "n"; then
        err "未插入。请手动把上面的 location ~ \\.php\$ 加进 $site"
        return 1
    fi

    local bak="${site}.fmgr-php.bak.$(date +%Y%m%d%H%M%S)"
    cp -a "$site" "$bak"
    ok "已备份 → $bak"

    if grep -qE '^[[:space:]]*location[[:space:]]' "$site"; then
        sed -i "0,/^[[:space:]]*location /s|^[[:space:]]*location |    # BEGIN_FMGR_ENSURE_PHP\n    location ~ \\.php\$ {\n        include fastcgi.conf;\n        fastcgi_pass $sock;\n        fastcgi_index index.php;\n    }\n    # END_FMGR_ENSURE_PHP\n\n&|" "$site"
    elif grep -qE '^[[:space:]]*server_name[[:space:]]' "$site"; then
        sed -i "/server_name/a\\    # BEGIN_FMGR_ENSURE_PHP\\n    location ~ \\.php\$ {\\n        include fastcgi.conf;\\n        fastcgi_pass $sock;\\n        fastcgi_index index.php;\\n    }\\n    # END_FMGR_ENSURE_PHP" "$site"
    else
        err "找不到插入点，已中止。备份在 $bak，请手动编辑"
        return 1
    fi

    if site_has_php "$site"; then
        ok "已插入 PHP 块（标记 BEGIN_FMGR_ENSURE_PHP）"
        warn "请立刻：sudo nginx -t && 浏览器访问 /fmgr/index.php 核对"
        warn "有问题可恢复：sudo cp $bak $site"
        return 0
    fi
    err "插入后仍检测不到 PHP，已保留备份 $bak，请手动处理"
    return 1
}

remove_ensured_php() {
    local f="$1"
    if grep -q '# BEGIN_FMGR_ENSURE_PHP' "$f" 2>/dev/null; then
        sed -i '/# BEGIN_FMGR_ENSURE_PHP/,/# END_FMGR_ENSURE_PHP/d' "$f"
        ok "已移除 $f 里本脚本插入的 PHP 块（BEGIN_FMGR_ENSURE_PHP）"
    fi
}

# 用户与 www-data 都能读写 FMGR_PARENT / fmgr（2775 + 属组 www-data）
fix_fmgr_perms() {
    log "设置权限：${CURRENT_USER}:${WWW_GROUP} 双方可读写..."
    mkdir -p "$FMGR_DST/files/tempUpload"

    if ! getent group "$WWW_GROUP" >/dev/null 2>&1; then
        warn "未找到组 $WWW_GROUP，改用 $CURRENT_USER"
        WWW_GROUP="$CURRENT_USER"
    else
        usermod -aG "$WWW_GROUP" "$CURRENT_USER" 2>/dev/null || true
    fi

    # 路径可进入
    local p="$FMGR_PARENT"
    while [ -n "$p" ] && [ "$p" != "/" ]; do
        [ -d "$p" ] && chmod a+x "$p" 2>/dev/null || true
        p=$(dirname "$p")
    done

    # 整个父目录：用户与 nginx 组共享读写（新文件继承组）
    chown -R "$CURRENT_USER:$WWW_GROUP" "$FMGR_PARENT"
    find "$FMGR_PARENT" -type d -exec chmod 2775 {} \;
    find "$FMGR_PARENT" -type f -exec chmod 664 {} \;
    chmod -R ug+rwX "$FMGR_DST/files"
    chmod g+s "$FMGR_DST/files" "$FMGR_DST/files/tempUpload" 2>/dev/null || true

    if id www-data >/dev/null 2>&1 && sudo -u www-data test -r "$FMGR_DST/index.php" 2>/dev/null \
        && sudo -u www-data test -w "$FMGR_DST/files" 2>/dev/null; then
        ok "www-data 可读 PHP、可写 files/"
    else
        err "www-data 仍无法正常访问 $FMGR_DST —— 检查路径权限"
        err "自检：sudo -u www-data test -r $FMGR_DST/index.php && echo OK"
    fi
    ok "权限：${CURRENT_USER}:${WWW_GROUP}，目录 2775 / 文件 664（双方读写）"
    warn "若刚把用户加入 $WWW_GROUP，需重新登录后组才生效"
}

do_install() {
    [ -f "$SNIPPET_SRC" ]   || { err "找不到 snippet：$SNIPPET_SRC"; exit 1; }
    [ -f "$SITE_SRC" ]      || { err "找不到独立站模板：$SITE_SRC"; exit 1; }
    [ -d "$FMGR_SRC_REPO" ] || { err "找不到 fmgr 源：$FMGR_SRC_REPO"; exit 1; }
    command -v apt >/dev/null 2>&1 || { err "非 Debian/Ubuntu"; exit 1; }

    log "==== fmgr 部署 ===="
    if [ "$BATCH" -eq 1 ]; then
        ok "非交互 --batch：FMGR_PARENT=$FMGR_PARENT（不提问）"
    else
        ask "fmgr 部署到哪个父目录" "$FMGR_PARENT" FMGR_PARENT
    fi
    FMGR_DST="$FMGR_PARENT/fmgr"
    ok "目标：$FMGR_DST"

    if ! command -v nginx >/dev/null 2>&1; then
        log "安装 nginx..."
        apt update
        DEBIAN_FRONTEND=noninteractive apt install -y nginx
    else ok "nginx 已安装"; fi

    if ! command -v php-fpm >/dev/null 2>&1 && ! ls /usr/sbin/php*-fpm >/dev/null 2>&1; then
        log "安装 php-fpm..."
        DEBIAN_FRONTEND=noninteractive apt install -y php-fpm
    else ok "php-fpm 已安装"; fi

    log "PHP 扩展：mbstring zip xml gd"
    DEBIAN_FRONTEND=noninteractive apt install -y php-mbstring php-zip php-xml php-gd || \
        warn "部分扩展安装失败"

    local php_sock
    php_sock=$(detect_php_socket)
    ok "PHP-FPM socket: $php_sock"

    log "同步 fmgr → $FMGR_DST"
    mkdir -p "$FMGR_PARENT" "$FMGR_DST"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a \
            --exclude 'NginxSetup' --exclude '.git' --exclude '.idea' \
            "$FMGR_SRC_REPO/" "$FMGR_DST/"
    else
        cp -a "$FMGR_SRC_REPO/." "$FMGR_DST/"
        rm -rf "$FMGR_DST/NginxSetup" "$FMGR_DST/.git" "$FMGR_DST/.idea" 2>/dev/null || true
    fi
    ok "fmgr 本体已就位（含 MoveToParent；父目录跳转页稍后另拷）"

    if [ "$BATCH" -eq 1 ]; then
        ok "非交互 --batch：NGINX_MODE=$NGINX_MODE FMGR_PARENT=$FMGR_PARENT"
        case "$NGINX_MODE" in
            snippet|standalone|skip) ;;
            *) err "--batch 时 NGINX_MODE 必须是 snippet|standalone|skip"; exit 1 ;;
        esac
    else
        echo ""
        ask_choice "请选择 nginx 配置方式（按机器情况选）：" 1 \
            "snippet: 挂到现有 site（Server 已有主站时推荐）" \
            "standalone: 独立站 fmgr_sites 听 80（须先关其他 80）" \
            "skip: 跳过 nginx 配置"
        case "$CHOICE" in
            snippet*)    NGINX_MODE="snippet" ;;
            standalone*) NGINX_MODE="standalone" ;;
            skip*)       NGINX_MODE="skip" ;;
        esac
    fi

    local replace_root=0
    local target_site=""

    case "$NGINX_MODE" in
        snippet)
            mkdir -p /etc/nginx/snippets
            cp "$SNIPPET_SRC" "$NGINX_SNIPPET"
            chmod 0644 "$NGINX_SNIPPET"
            ok "已写入 $NGINX_SNIPPET（仅 /fmgr /x，无 PHP）"

            # 解析目标 site
            if [ -n "$TARGET_SITE" ] && [ -f "$TARGET_SITE" ]; then
                target_site="$TARGET_SITE"
                ok "使用 TARGET_SITE=$target_site"
            elif [ "$BATCH" -eq 1 ]; then
                if [ -f /etc/nginx/sites-available/html.conf ]; then
                    target_site=/etc/nginx/sites-available/html.conf
                elif [ -f /etc/nginx/sites-available/http ]; then
                    target_site=/etc/nginx/sites-available/http
                else
                    err "--batch 未设置 TARGET_SITE，且没有 html.conf；无法挂 snippet"
                    exit 1
                fi
                ok "batch 选用 $target_site"
            else
                echo ""
                local sites=()
                local site
                while IFS= read -r site; do
                    [ -n "$site" ] && sites+=("$site")
                done < <(list_sites)
                if [ "${#sites[@]}" -eq 0 ]; then
                    warn "sites-enabled 为空。请手动：include $NGINX_SNIPPET; 并确保有 PHP"
                else
                    echo "当前 sites-enabled："
                    ask_choice "选择要挂 fmgr 的 site" 1 "${sites[@]}"
                    target_site="/etc/nginx/sites-enabled/$CHOICE"
                    if [ -L "$target_site" ]; then
                        target_site=$(readlink -f "$target_site")
                    fi
                fi
            fi

            if [ -n "$target_site" ]; then
                if [ "$BATCH" -eq 1 ]; then
                    # 非交互：只检测 PHP，绝不插入
                    if site_has_php "$target_site"; then
                        ok "$target_site 已有 PHP，不修改"
                    else
                        warn "$target_site 未见 PHP —— batch 不自动插入。请确认 site 已有 location ~ \\.php\$"
                    fi
                else
                    ensure_site_php "$target_site" "$php_sock" || true
                fi
                warn "【必查】$target_site 须有 PHP + include $NGINX_SNIPPET;"

                local cur_root
                cur_root=$(grep -oE '^[[:space:]]*root[[:space:]]+[^;]+;' "$target_site" 2>/dev/null | head -1 | sed 's/^[[:space:]]*root[[:space:]]*//;s/;$//' | tr -d ' ')
                log "当前 root: ${cur_root:-（未检测到）}"
                if [ -z "$cur_root" ] || [ "$cur_root" != "$FMGR_PARENT" ]; then
                    if [ "$BATCH" -eq 1 ] || ask_yn "把 root 改为 $FMGR_PARENT？" "y"; then
                        if grep -qE '^[[:space:]]*root[[:space:]]+' "$target_site"; then
                            sed -i -E "0,/^[[:space:]]*root[[:space:]]+[^;]+;/{s|^[[:space:]]*root[[:space:]]+[^;]+;|    root $FMGR_PARENT;|}" "$target_site"
                        else
                            sed -i "/server_name/a\\    root $FMGR_PARENT;" "$target_site"
                        fi
                        ok "root → $FMGR_PARENT"
                        replace_root=1
                    else
                        warn "root 不是 $FMGR_PARENT 时 /fmgr 可能 404"
                    fi
                else
                    replace_root=1
                    ok "root 已是 $FMGR_PARENT"
                fi

                # include（--batch 一律启用，不提问）
                if grep -qE "^[[:space:]]*include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;" "$target_site" 2>/dev/null; then
                    ok "已有 include 行"
                elif grep -qE "^[[:space:]]*#[[:space:]]*include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;" "$target_site" 2>/dev/null; then
                    if [ "$BATCH" -eq 1 ] || ask_yn "取消注释 include 行？" "y"; then
                        sed -i -E "s|^[[:space:]]*#[[:space:]]*(include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;)|    \1|" "$target_site"
                        ok "已取消注释 include"
                    else
                        warn "请手动：include $NGINX_SNIPPET;"
                    fi
                else
                    if [ "$BATCH" -eq 1 ] || ask_yn "在 $target_site 自动插入 include？" "y"; then
                        if grep -qE '^[[:space:]]*location[[:space:]]' "$target_site"; then
                            sed -i "0,/^[[:space:]]*location /s|^[[:space:]]*location |    include $NGINX_SNIPPET;\n\n&|" "$target_site"
                        else
                            sed -i "/server_name/a\\    include $NGINX_SNIPPET;" "$target_site"
                        fi
                        ok "已插入 include"
                    else
                        warn "请手动：include $NGINX_SNIPPET;"
                    fi
                fi

                # GNOME html.conf：注释掉会挡脚本的 DENY 段（仅处理带标记的块）
                if grep -q '# BEGIN_DENY_DYNAMIC' "$target_site" 2>/dev/null; then
                    if [ "$BATCH" -eq 1 ] || ask_yn "注释 BEGIN_DENY_DYNAMIC 段（避免拦 /fmgr/*.php）？" "y"; then
                        sed -i '/# BEGIN_DENY_DYNAMIC/,/# END_DENY_DYNAMIC/s/^/# /' "$target_site"
                        ok "已注释 DENY_DYNAMIC 段"
                    fi
                fi
            fi
            ;;

        standalone)
            mkdir -p /etc/nginx/snippets /etc/nginx/sites-available

            cp "$SNIPPET_SRC" "$NGINX_SNIPPET"
            chmod 0644 "$NGINX_SNIPPET"
            ok "已写入 $NGINX_SNIPPET（仅路径；PHP 在 fmgr_sites）"

            sed \
                -e "s|__FMGR_PARENT__|$FMGR_PARENT|g" \
                -e "s|__PHP_SOCK__|$php_sock|g" \
                "$SITE_SRC" > "$STANDALONE_SITE_AVAIL"
            chmod 0644 "$STANDALONE_SITE_AVAIL"
            ok "已写入 $STANDALONE_SITE_AVAIL"
            replace_root=1

            if [ "$BATCH" -eq 1 ]; then
                warn "--batch 下 standalone 只写入 available，不自动 disable 其它站、不自动启用"
                warn "启用前请自行处理 80 冲突后：ln -sfn $STANDALONE_SITE_AVAIL $STANDALONE_SITE_EN"
            else
                echo ""
                warn "独立站 listen 80。启用前必须关掉其他占用 80 的 site。"
                local conflicts=()
                local c
                while IFS= read -r c; do
                    [ -n "$c" ] && conflicts+=("$c")
                done < <(list_port80_sites)

                if [ "${#conflicts[@]}" -gt 0 ]; then
                    warn "当前占用 80 的 site：${conflicts[*]}"
                    if ask_yn "现在 disable 这些 site？" "y"; then
                        for c in "${conflicts[@]}"; do
                            rm -f "/etc/nginx/sites-enabled/$c"
                            ok "已 disable：$c"
                        done
                    fi
                fi

                if [ -L /etc/nginx/sites-enabled/fmgr ] || [ -f /etc/nginx/sites-enabled/fmgr ]; then
                    rm -f /etc/nginx/sites-enabled/fmgr
                fi

                if ask_yn "启用 fmgr_sites？" "y"; then
                    conflicts=()
                    while IFS= read -r c; do
                        [ -n "$c" ] && conflicts+=("$c")
                    done < <(list_port80_sites)
                    if [ "${#conflicts[@]}" -gt 0 ]; then
                        err "仍有 80 冲突：${conflicts[*]}。未启用。"
                    else
                        ln -sfn "$STANDALONE_SITE_AVAIL" "$STANDALONE_SITE_EN"
                        ok "已启用 $STANDALONE_SITE_EN"
                    fi
                else
                    warn "未启用。需要时：sudo ln -sfn $STANDALONE_SITE_AVAIL $STANDALONE_SITE_EN"
                fi
            fi
            ;;

        skip)
            warn "跳过 nginx 配置"
            ;;
    esac

    if [ "$replace_root" -eq 1 ] && [ -d "$FMGR_SRC_REPO/MoveToParent" ]; then
        log "MoveToParent → $FMGR_PARENT/"
        cp -an "$FMGR_SRC_REPO/MoveToParent/." "$FMGR_PARENT/" 2>/dev/null \
            || cp -a "$FMGR_SRC_REPO/MoveToParent/." "$FMGR_PARENT/"

        local has_index="无"
        [ -f "$FMGR_PARENT/index.html" ] && has_index="有"
        log "当前 index.html: $has_index"
        if [ "$BATCH" -eq 1 ]; then
            ok "batch 首页模式：$HOMEPAGE_MODE"
        else
            echo ""
            ask_choice "首页处理：" 1 \
                "jump: 跳转页（覆盖 index.html）" \
                "404: 404页（覆盖 index.html）" \
                "none: 不处理"
            case "$CHOICE" in
                jump*) HOMEPAGE_MODE="jump" ;;
                404*)  HOMEPAGE_MODE="404" ;;
                none*) HOMEPAGE_MODE="none" ;;
            esac
        fi
        case "$HOMEPAGE_MODE" in
            jump)
                [ -f "$FMGR_PARENT/jumpindex.html" ] && cp "$FMGR_PARENT/jumpindex.html" "$FMGR_PARENT/index.html" && ok "首页=跳转页" \
                    || warn "无 jumpindex.html"
                ;;
            404)
                [ -f "$FMGR_PARENT/404index.html" ] && cp "$FMGR_PARENT/404index.html" "$FMGR_PARENT/index.html" && ok "首页=404页" \
                    || warn "无 404index.html"
                ;;
            none) ok "不处理首页" ;;
            *) warn "未知 HOMEPAGE_MODE=$HOMEPAGE_MODE，跳过" ;;
        esac
    else
        ok "未替换 root，跳过 MoveToParent"
    fi

    fix_fmgr_perms

    if command -v nginx >/dev/null 2>&1; then
        log "nginx -t ..."
        if nginx -t 2>&1; then
            ok "nginx 配置校验通过"
            reload_nginx_if_running
        else
            err "nginx -t 失败"
            exit 1
        fi
    fi

    cat <<EOF

==============================================
✓ fmgr 文件已部署 —— 请按清单核对后再用

【怎么部署】
  GNOME 新机器 : Init 已配 html.conf + snippet（一般不用再选 standalone）
  Server 有主站 : 本脚本选 snippet，挂到现有 site
  单独开 80 站  : 选 standalone（先 disable 其它听 80 的站）

【本次】
  目录           : $FMGR_DST
  访问           : http://<本机>/fmgr/  或  /x
  上传目录       : $FMGR_DST/files  (组 $WWW_GROUP 可写)
  PHP socket     : $php_sock
EOF
    case "$NGINX_MODE" in
        snippet)
            echo "  方式           : snippet → $NGINX_SNIPPET"
            [ -n "$target_site" ] && echo "  挂到 site      : $target_site"
            echo "  PHP            : 必须在 site 里（snippet 无 PHP）；脚本默认不乱改"
            ;;
        standalone)
            echo "  方式           : $STANDALONE_SITE_AVAIL"
            if [ -e "$STANDALONE_SITE_EN" ]; then echo "  状态           : 已启用"
            else echo "  状态           : 未启用（available 已写好）"; fi
            echo "  PHP            : 在 fmgr_sites 内，不在 snippet"
            ;;
        skip) echo "  方式           : 跳过 nginx（需你自己配）" ;;
    esac
    cat <<EOF

【必查】
  1. site 内有 location ~ \\.php\$，且能处理 /fmgr/*.php
  2. site 内有：include $NGINX_SNIPPET;
  3. site 的 root = $FMGR_PARENT
  4. sudo nginx -t && sudo systemctl reload nginx
  5. sudo -u www-data test -r $FMGR_DST/index.php && echo OK
  6. 浏览器打开 /fmgr/index.php 出现登录页

  启动（如未开）：sudo systemctl start php*-fpm nginx

  ! 立刻改默认弱口令（admin/user/405/123456 等）见仓库 README.md

  卸载：./setupNginxForFmgr.sh --uninstall
==============================================
EOF
}

do_uninstall() {
    log "==== fmgr 卸载 ===="
    ask "要卸载的 fmgr 父目录" "$FMGR_PARENT" FMGR_PARENT
    FMGR_DST="$FMGR_PARENT/fmgr"

    local keep_uploads=1
    if [ "$PURGE" -eq 0 ]; then
        if ask_yn "保留上传文件到 fmgr.files.bak？" "y"; then
            keep_uploads=1
        else
            keep_uploads=0
            ask_yn "确认强删全部？" "n" || { warn "已取消"; exit 0; }
        fi
    else
        keep_uploads=0
    fi

    local SITES_DIR=/etc/nginx/sites-enabled
    local TOUCHED_FILES=""
    if [ -d "$SITES_DIR" ]; then
        local f real
        for f in "$SITES_DIR"/*; do
            [ -e "$f" ] || continue
            real="$f"
            [ -L "$f" ] && real=$(readlink -f "$f" || echo "$f")
            if grep -qE "^[[:space:]]*include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;" "$real" 2>/dev/null; then
                sed -i -E "s|^([[:space:]]*)include[[:space:]]+${NGINX_SNIPPET}[[:space:]]*;|\1# include ${NGINX_SNIPPET};|" "$real"
                TOUCHED_FILES="$TOUCHED_FILES $real"
                ok "已注释 include：$real"
            fi
            remove_ensured_php "$real"
        done
    fi
    # 也扫 sites-available（可能已 disable）
    if [ -d /etc/nginx/sites-available ]; then
        for f in /etc/nginx/sites-available/*; do
            [ -f "$f" ] || continue
            remove_ensured_php "$f"
        done
    fi

    for en in "$STANDALONE_SITE_EN" /etc/nginx/sites-enabled/fmgr; do
        if [ -L "$en" ] || [ -f "$en" ]; then
            rm -f "$en"
            ok "已禁用 $(basename "$en")"
        fi
    done
    for av in "$STANDALONE_SITE_AVAIL" /etc/nginx/sites-available/fmgr; do
        if [ -f "$av" ]; then
            rm -f "$av"
            ok "已删除 $av"
        fi
    done

    if [ -f "$NGINX_SNIPPET" ]; then
        rm -f "$NGINX_SNIPPET"
        ok "已删除 $NGINX_SNIPPET"
    fi

    if [ -d "$FMGR_DST" ]; then
        local UPLOAD_DIR="$FMGR_DST/files"
        local BACKUP_DIR="${FMGR_DST}.files.bak"
        if [ "$keep_uploads" -eq 1 ] && [ -d "$UPLOAD_DIR" ]; then
            if [ -d "$BACKUP_DIR" ]; then
                cp -a "$UPLOAD_DIR/." "$BACKUP_DIR/" 2>/dev/null || true
            else
                mv "$UPLOAD_DIR" "$BACKUP_DIR"
            fi
            ok "上传文件备份：$BACKUP_DIR"
        fi
        rm -rf "$FMGR_DST"
        ok "已删除 $FMGR_DST"
    fi

    if command -v nginx >/dev/null 2>&1; then
        if nginx -t 2>&1; then
            ok "nginx -t 通过"
            reload_nginx_if_running
        else
            err "nginx -t 失败"
            exit 1
        fi
    fi

    cat <<EOF

==============================================
✓ fmgr 卸载完成（未卸 nginx/php-fpm 系统包）
==============================================
EOF
}

ACTION="install"
PURGE=0
for arg in "$@"; do
    case "$arg" in
        --uninstall|-u) ACTION="uninstall" ;;
        --purge)        PURGE=1 ;;
        --yes|-y)       ASSUME_YES=1 ;;
        --batch|-b)
            BATCH=1
            ASSUME_YES=1
            ;;
        --help|-h)
            sed -n '2,25p' "$0"
            exit 0 ;;
        *) err "未知参数: $arg"; exit 2 ;;
    esac
done

if [ "$(id -u)" -ne 0 ]; then
    log "需要 root，sudo 重跑..."
    exec sudo -E bash "$0" "$@"
fi

if [ "$ACTION" = "uninstall" ]; then
    do_uninstall
else
    do_install
fi

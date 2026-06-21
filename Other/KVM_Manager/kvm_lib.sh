#!/bin/bash
# KVM 管理脚本公共库：依赖检查、输出格式、virsh 封装、本地配置

set -euo pipefail

KVM_MANAGER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KVM_CONFIG_FILE="${KVM_CONFIG_FILE:-$KVM_MANAGER_DIR/kvm.local.conf}"

# 颜色（若终端不支持可设 NO_COLOR=1）
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
    _C_RED='\033[31m'
    _C_GREEN='\033[32m'
    _C_YELLOW='\033[33m'
    _C_CYAN='\033[36m'
    _C_BOLD='\033[1m'
    _C_RESET='\033[0m'
else
    _C_RED='' _C_GREEN='' _C_YELLOW='' _C_CYAN='' _C_BOLD='' _C_RESET=''
fi

kvm_die() {
    echo -e "${_C_RED}错误:${_C_RESET} $*" >&2
    exit 1
}

kvm_warn() {
    echo -e "${_C_YELLOW}警告:${_C_RESET} $*" >&2
}

kvm_info() {
    echo -e "${_C_CYAN}$*${_C_RESET}"
}

kvm_ok() {
    echo -e "${_C_GREEN}$*${_C_RESET}"
}

kvm_heading() {
    echo -e "${_C_BOLD}=== $* ===${_C_RESET}"
}

# 读取 kvm.local.conf（环境变量 KVM_VIRSH_URI 优先，不覆盖）
kvm_config_load() {
    if [ -n "${KVM_VIRSH_URI:-}" ]; then
        return
    fi
    if [ -f "$KVM_CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        source "$KVM_CONFIG_FILE"
    fi
}

kvm_config_save() {
    local uri="$1"
    cat > "$KVM_CONFIG_FILE" <<EOF
# KVM Manager 本地配置（可手工编辑）
# 重新配置: ./kvm_info.sh --setup
# 示例见 kvm.conf.example

KVM_VIRSH_URI="$uri"
EOF
    KVM_VIRSH_URI="$uri"
}

kvm_config_hint() {
    echo
    kvm_info "配置已写入: $KVM_CONFIG_FILE"
    kvm_info "下次可直接运行脚本；修改连接请编辑 KVM_VIRSH_URI，或执行: ./kvm_info.sh --setup"
    echo
}

# 探测 URI 是否可用及 VM 数量
kvm_probe_uri() {
    local uri="$1"
    local count
    if ! virsh -c "$uri" uri &>/dev/null; then
        echo "不可连接"
        return 1
    fi
    count=$(virsh -c "$uri" list --all --name 2>/dev/null | sed '/^$/d' | wc -l)
    echo "可连接, ${count} 台虚拟机"
}

# 首次 / 重新配置向导
kvm_config_wizard() {
    if [ ! -t 0 ]; then
        kvm_die "未找到配置 $KVM_CONFIG_FILE。请在本机交互运行: ./kvm_info.sh --setup；或设置环境变量 KVM_VIRSH_URI。"
    fi

    kvm_require_virsh_cmd

    local sys_note session_note default_uri_note
    sys_note=$(kvm_probe_uri "qemu:///system" || true)
    session_note=$(kvm_probe_uri "qemu:///session" || true)

    kvm_heading "KVM Manager 配置"
    echo
    echo "请选择 libvirt 连接（决定 virsh 访问哪套虚拟机）："
    echo
    printf "  1) qemu:///system   系统级 VM     [%s]\n" "${sys_note:-不可连接}"
    printf "  2) qemu:///session  用户会话 VM   [%s]\n" "${session_note:-不可连接}"
    echo "  3) 自定义 URI"
    echo "  4) 使用 virsh 当前默认"
    echo

    if [[ "${sys_note:-}" == *"可连接"* ]] && [[ "${sys_note:-}" != *"0 台"* ]]; then
        default_uri_note="1"
    elif [[ "${session_note:-}" == *"可连接"* ]]; then
        default_uri_note="2"
    else
        default_uri_note="1"
    fi

    echo -n "请输入序号 [默认 ${default_uri_note}]: "
    read -r choice
    choice="${choice:-$default_uri_note}"

    local selected_uri=""
    case "$choice" in
        1)
            selected_uri="qemu:///system"
            ;;
        2)
            selected_uri="qemu:///session"
            ;;
        3)
            echo -n "请输入 URI（如 qemu:///system）: "
            read -r selected_uri
            [ -n "$selected_uri" ] || kvm_die "URI 不能为空"
            ;;
        4)
            selected_uri=$(virsh uri 2>/dev/null || true)
            [ -n "$selected_uri" ] || kvm_die "无法读取 virsh 默认 URI"
            ;;
        *)
            kvm_die "无效选择: $choice"
            ;;
    esac

    if ! virsh -c "$selected_uri" uri &>/dev/null; then
        kvm_die "无法连接: $selected_uri（请检查 libvirtd 与用户权限，如 sudo usermod -aG libvirt \"\$USER\"）"
    fi

    kvm_config_save "$selected_uri"
    kvm_ok "已选择: $selected_uri"
    kvm_config_hint
}

# 无配置时进入向导；KVM_FORCE_SETUP=1 强制重新配置
kvm_ensure_config() {
    kvm_config_load
    if [ -n "${KVM_VIRSH_URI:-}" ] && [ "${KVM_FORCE_SETUP:-0}" != 1 ]; then
        return
    fi
    if [ "${KVM_FORCE_SETUP:-0}" = 1 ]; then
        kvm_config_wizard
        return
    fi
    if [ ! -f "$KVM_CONFIG_FILE" ]; then
        kvm_info "首次运行，进入配置向导…"
        echo
        kvm_config_wizard
    fi
    kvm_config_load
    [ -n "${KVM_VIRSH_URI:-}" ] || kvm_die "未配置 KVM_VIRSH_URI。请运行: ./kvm_info.sh --setup"
}

# 统一 virsh 调用（使用已配置的 URI）
kvm_virsh() {
    if [ -z "${KVM_VIRSH_URI:-}" ]; then
        virsh "$@"
    else
        virsh -c "$KVM_VIRSH_URI" "$@"
    fi
}

kvm_require_virsh_cmd() {
    if ! command -v virsh &>/dev/null; then
        kvm_die "未找到 virsh。请安装 libvirt-clients：sudo apt install libvirt-clients"
    fi
}

# 检查 virsh / libvirt 连接
kvm_require_virsh() {
    kvm_require_virsh_cmd
    if ! kvm_virsh uri &>/dev/null; then
        kvm_die "无法连接 libvirt（${KVM_VIRSH_URI:-默认}）。请确认 libvirtd 已运行且当前用户有权限，或运行 ./kvm_info.sh --setup 更换连接。"
    fi
}

# 创建/define VM 等写入 system 级 libvirt 时需 root 或 libvirt 组
kvm_require_libvirt_write() {
    kvm_config_load
    local uri="${KVM_VIRSH_URI:-qemu:///system}"
    [[ "$uri" == *"/system" ]] || return 0
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    if groups 2>/dev/null | grep -qw libvirt; then
        return 0
    fi
    kvm_die "写入 libvirt（$uri）需要 root 或 libvirt 组。请用: sudo ./kvm.sh ；或: sudo usermod -aG libvirt \"\$USER\" 后重新登录"
}

# 列出所有域名（含 shutdown），每行一个
kvm_list_domains() {
    kvm_virsh list --all --name 2>/dev/null | sed '/^$/d'
}

# 域名是否存在
kvm_domain_exists() {
    local name="$1"
    kvm_virsh dominfo "$name" &>/dev/null
}

# 解析域名：无参数时交互选择；有参数则校验；支持前缀模糊匹配
kvm_resolve_domain() {
    local arg="${1:-}"
    if [ -n "$arg" ]; then
        if kvm_domain_exists "$arg"; then
            echo "$arg"
            return
        fi
        local -a matches=()
        local d
        while IFS= read -r d; do
            [ -n "$d" ] && matches+=("$d")
        done < <(kvm_list_domains | grep -F -- "$arg" || true)
        if [ "${#matches[@]}" -eq 1 ]; then
            kvm_info "匹配虚拟机: ${matches[0]}" >&2
            echo "${matches[0]}"
            return
        fi
        if [ "${#matches[@]}" -gt 1 ]; then
            kvm_warn "名称 \"$arg\" 匹配多台虚拟机：" >&2
            printf '  - %s\n' "${matches[@]}" >&2
            kvm_die "请指定更完整的名称"
        fi
        kvm_die "虚拟机不存在: $arg"
    fi

    if [ ! -t 0 ]; then
        kvm_die "未指定虚拟机。用法: $0 <命令> <名称>；或交互运行本脚本"
    fi

    local -a domains
    mapfile -t domains < <(kvm_list_domains)
    if [ "${#domains[@]}" -eq 0 ]; then
        kvm_die "当前没有任何虚拟机（连接: ${KVM_VIRSH_URI:-默认}）。可运行 ./0-kvm_info.sh --setup 更换 libvirt 连接。"
    fi

    echo "可选虚拟机：" >&2
    local i=1
    for d in "${domains[@]}"; do
        local state disk_hint
        state=$(kvm_virsh domstate "$d" 2>/dev/null || echo "?")
        disk_hint=$(kvm_domain_primary_disk "$d" 2>/dev/null || echo "")
        if [ -n "$disk_hint" ] && [[ "$disk_hint" != \[volume:* ]]; then
            disk_hint=$(basename "$disk_hint")
        else
            disk_hint="-"
        fi
        printf "  %2d) %-22s [%s]  %s\n" "$i" "$d" "$state" "$disk_hint" >&2
        ((i++)) || true
    done
    echo -n "请输入序号或名称（空回车取消）: " >&2
    read -r choice || true
    if [ -z "$choice" ]; then
        kvm_warn "已取消" >&2
        return 1
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#domains[@]}" ]; then
        echo "${domains[$((choice - 1))]}"
        return 0
    fi
    if kvm_domain_exists "$choice"; then
        echo "$choice"
        return 0
    fi
    kvm_warn "无效选择: $choice" >&2
    return 1
}

# 人类可读内存（KiB 输入）
kvm_format_kib() {
    local kib="$1"
    if [ "$kib" -ge 1048576 ]; then
        awk -v k="$kib" 'BEGIN { printf "%.2f GiB", k/1048576 }'
    elif [ "$kib" -ge 1024 ]; then
        awk -v k="$kib" 'BEGIN { printf "%.2f MiB", k/1024 }'
    else
        echo "${kib} KiB"
    fi
}

# 获取 VM 状态（virsh 原文，可能是中文）
kvm_domain_state() {
    kvm_virsh domstate "$1" 2>/dev/null || echo "unknown"
}

# 状态是否匹配（兼容中英文 virsh）
kvm_domain_state_is() {
    local current="$1"
    local target="$2"
    case "$target" in
        running)
            [[ "$current" == "running" || "$current" == "运行" ]]
            ;;
        "shut off"|shutoff)
            [[ "$current" == "shut off" || "$current" == "关闭" ]]
            ;;
        paused)
            [[ "$current" == "paused" || "$current" == "暂停" ]]
            ;;
        *)
            [ "$current" = "$target" ]
            ;;
    esac
}

kvm_domain_is_running() {
    local state
    state=$(kvm_domain_state "$1")
    kvm_domain_state_is "$state" running || \
        [[ "$state" == "shutting down" || "$state" == "正在关闭" ]]
}

# 强制断电
kvm_domain_force_stop() {
    local domain="$1"
    kvm_virsh destroy "$domain"
    if kvm_wait_state "$domain" "shut off" 15; then
        kvm_ok "已强制关闭: $domain"
    else
        kvm_warn "已发送 destroy，请检查: virsh domstate $domain"
    fi
}

# VM 是否可能有 Guest OS 响应 ACPI 关机
kvm_domain_has_guest_os() {
    local domain="$1"
    [ "$(kvm_domain_disk_paths "$domain" | wc -l)" -gt 0 ]
}

# 等待 VM 进入目标状态
kvm_wait_state() {
    local domain="$1"
    local target="$2"
    local timeout="${3:-60}"
    local i=0
    while [ "$i" -lt "$timeout" ]; do
        kvm_domain_state_is "$(kvm_domain_state "$domain")" "$target" && return 0
        sleep 1
        ((i++)) || true
    done
    return 1
}

# 交互确认（y/Y 才继续）
kvm_confirm() {
    local prompt="$1"
    if [ ! -t 0 ]; then
        kvm_die "非交互环境，已取消: $prompt"
    fi
    echo -n "$prompt [y/N]: " >&2
    read -r ans || true
    [[ "$ans" =~ ^[Yy]$ ]]
}

# 要求 VM 已关机（修改 XML / 网卡 / 共享时）
kvm_require_shutoff() {
    local domain="$1"
    if kvm_domain_is_running "$domain"; then
        kvm_die "虚拟机 $domain 正在运行。请先关机: ./kvm_vm.sh shutdown $domain"
    fi
}

# 从 VM XML 列出依赖的 libvirt 虚拟网络名
kvm_domain_virt_networks() {
    local domain="$1"
    kvm_virsh dumpxml "$domain" | awk '
        /<source network=/ { split($0, a, "'\''"); if (a[2] != "") print a[2] }
    ' | sort -u
}

# 虚拟网络是否已激活（兼容中英文 virsh 输出）
kvm_net_is_active() {
    local net="$1" state
    # net-list 更可靠（net-info 在中文环境下用全角冒号）
    state=$(kvm_virsh net-list 2>/dev/null | awk -v n="$net" '$1 == n { print $2; exit }')
    if [ -n "$state" ]; then
        [[ "$state" == "active" || "$state" == "活动" || "$state" == "running" || "$state" == "运行" ]]
        return
    fi
    state=$(kvm_virsh net-info "$net" 2>/dev/null | awk '
        /Active|活跃/ {
            if (match($0, /(yes|no|是|否)/)) { print substr($0, RSTART, RLENGTH); exit }
        }
    ')
    [[ "$state" == "yes" || "$state" == "是" ]]
}

# 启动 libvirt 虚拟网络
kvm_net_start() {
    local net="$1" out
    kvm_virsh net-info "$net" &>/dev/null || kvm_die "虚拟网络不存在: $net"
    if kvm_net_is_active "$net"; then
        return 0
    fi
    kvm_info "启动虚拟网络: $net"
    if out=$(kvm_virsh net-start "$net" 2>&1); then
        kvm_ok "虚拟网络已激活: $net"
        return 0
    fi
    if echo "$out" | grep -qiE 'already active|已经激活|已在运行|already running'; then
        return 0
    fi
    kvm_die "$out"
}

# 启动 VM 所需的全部虚拟网络（NAT 等）
kvm_ensure_domain_networks() {
    local domain="$1"
    local net
    while IFS= read -r net; do
        [ -n "$net" ] || continue
        kvm_net_start "$net"
    done < <(kvm_domain_virt_networks "$domain")
}

# VM 定义 XML 路径（探测常见目录，否则按 URI 推断）
kvm_domain_xml_path() {
    local name="$1"
    local p
    for p in \
        "/etc/libvirt/qemu/${name}.xml" \
        "${HOME}/.config/libvirt/qemu/${name}.xml"; do
        if [ -f "$p" ]; then
            echo "$p"
            return
        fi
    done
    local uri="${KVM_VIRSH_URI:-}"
    if [[ "$uri" == *"/system" ]]; then
        echo "/etc/libvirt/qemu/${name}.xml"
    elif [[ "$uri" == *"/session" ]]; then
        echo "${HOME}/.config/libvirt/qemu/${name}.xml"
    else
        echo "?"
    fi
}

# 从 dumpxml 提取磁盘/块设备路径（不含 cdrom）
kvm_domain_disk_paths() {
    local name="$1"
    kvm_virsh dumpxml "$name" | awk '
        /<disk / { in_disk=1; is_cdrom=0 }
        in_disk && /device='"'"'cdrom'"'"'/ { is_cdrom=1 }
        in_disk && /<source file='"'"'/ { split($0, a, "'\''"); if (!is_cdrom && a[2] != "") print a[2] }
        in_disk && /<source dev='"'"'/  { split($0, a, "'\''"); if (!is_cdrom && a[2] != "") print a[2] }
        in_disk && /<source pool=/ {
            # pool/volume 形式：尽量保留 vol 名供 virsh vol-path 解析
            match($0, /volume='"'"'[^'"'"']+'"'"'/)
            if (RSTART) { s=substr($0, RSTART+8, RLENGTH-9); if (!is_cdrom) print "[volume:" s "]" }
        }
        in_disk && /<\/disk>/ { in_disk=0; is_cdrom=0 }
    '
}

# 第一块主磁盘路径
kvm_domain_primary_disk() {
    kvm_domain_disk_paths "$1" | head -1
}

# 打印 VM 定义与磁盘路径（交互提示用）
kvm_print_domain_location() {
    local name="$1"
    local xml disk
    xml=$(kvm_domain_xml_path "$name")
    disk=$(kvm_domain_primary_disk "$name")
    echo "  定义 XML:  $xml"
    if [ -n "$disk" ] && [[ "$disk" != \[volume:* ]]; then
        echo "  磁盘:      $disk"
    elif [ -n "$disk" ]; then
        echo "  磁盘:      $disk"
    else
        echo "  磁盘:      （无）"
    fi
}

# 列出 VM 所有 file 型存储：kind|target|path（kind=disk|cdrom）
kvm_domain_file_sources() {
    local name="$1"
    kvm_virsh dumpxml "$name" | awk '
        /<disk / { in_disk=1; kind="disk"; tgt="" }
        in_disk && /device='"'"'cdrom'"'"'/ { kind="cdrom" }
        in_disk && /<target dev=/ { split($0, a, "'\''"); tgt=a[2] }
        in_disk && /<source file='"'"'/ { split($0, a, "'\''"); path=a[2] }
        in_disk && /<\/disk>/ {
            if (path != "") print kind "|" tgt "|" path
            in_disk=0; kind="disk"; tgt=""; path=""
        }
    '
}

# 启动前检查存储；缺失 ISO 可交互弹出
kvm_preflight_start_storage() {
    local domain="$1"
    local line kind target path missing_cdroms=0 missing_disks=0
    local -a cdrom_targets=()

    while IFS= read -r line; do
        [ -n "$line" ] || continue
        IFS='|' read -r kind target path <<< "$line"
        [ -e "$path" ] && continue
        if [ "$kind" = "cdrom" ]; then
            ((missing_cdroms++)) || true
            cdrom_targets+=("$target")
            kvm_warn "光盘 ${target:-?} 镜像不存在: $path"
        else
            ((missing_disks++)) || true
            kvm_warn "磁盘 ${target:-?} 不存在: $path"
        fi
    done < <(kvm_domain_file_sources "$domain")

    if [ "$missing_disks" -gt 0 ]; then
        kvm_die "存在缺失的磁盘文件，请先修复路径或挂载存储后再启动"
    fi

    if [ "$missing_cdroms" -eq 0 ]; then
        return 0
    fi

    local tgt
    for tgt in "${cdrom_targets[@]}"; do
        [ -n "$tgt" ] || continue
        if [ -t 0 ]; then
            if kvm_confirm "弹出缺失的光盘 ${tgt} 并继续启动?"; then
                kvm_info "弹出光盘: ${tgt}"
                kvm_virsh change-media "$domain" "$tgt" --eject --config
            else
                kvm_die "已取消。请补回 ISO 或手动: virsh change-media $domain $tgt --eject --config"
            fi
        else
            kvm_die "光盘 ${tgt} 镜像缺失。交互运行以弹出，或: virsh change-media $domain $tgt --eject --config"
        fi
    done

    if [ "$(kvm_domain_disk_paths "$domain" | wc -l)" -eq 0 ]; then
        kvm_warn "该 VM 没有硬盘，启动后可能无法引导操作系统"
        if [ -t 0 ]; then
            kvm_confirm "仍要启动?" || kvm_die "已取消"
        fi
    fi
}

# 打开 Spice/VNC 图形控制台（virt-viewer）
kvm_open_console() {
    local domain="$1"
    local viewer="${KVM_VIEWER:-virt-viewer}"
    local display_uri xauth

    command -v "$viewer" &>/dev/null || \
        kvm_die "未找到 $viewer。请安装: sudo apt install virt-viewer"

    kvm_domain_is_running "$domain" || kvm_die "虚拟机未运行，无法打开界面: $domain"

    display_uri=$(kvm_virsh domdisplay "$domain" 2>/dev/null || true)
    kvm_info "打开控制台: $domain${display_uri:+ ($display_uri)}"

    local -a viewer_cmd=("$viewer")
    [ -n "${KVM_VIRSH_URI:-}" ] && viewer_cmd+=(-c "$KVM_VIRSH_URI")
    viewer_cmd+=("$domain")

    # sudo 时用原登录用户开窗口，避免 DISPLAY 丢失
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        xauth="${XAUTHORITY:-}"
        [ -z "$xauth" ] && [ -f "/home/$SUDO_USER/.Xauthority" ] && xauth="/home/$SUDO_USER/.Xauthority"
        sudo -u "$SUDO_USER" env DISPLAY="${DISPLAY:-}" XAUTHORITY="${xauth:-}" \
            "${viewer_cmd[@]}" &
    else
        "${viewer_cmd[@]}" &
    fi
}

# ---------- 快照 ----------

# 列出 VM 快照名（每行一个）
kvm_snapshot_names() {
    local domain="$1"
    kvm_virsh snapshot-list "$domain" 2>/dev/null | awk 'NR > 2 && $1 != "" { print $1 }'
}

# 快照描述（来自 snapshot-dumpxml）
kvm_snapshot_description() {
    local domain="$1" snap="$2"
    kvm_virsh snapshot-dumpxml "$domain" "$snap" 2>/dev/null | sed -n 's/.*<description>\(.*\)<\/description>.*/\1/p' | head -1
}

# 是否当前快照
kvm_snapshot_is_current() {
    local domain="$1" snap="$2"
    kvm_virsh snapshot-info "$domain" "$snap" 2>/dev/null | grep -qE '(Current:[[:space:]]+yes|当前[：:][[:space:]]*是)'
}

# 快照创建时间（来自 snapshot-list 行）
kvm_snapshot_creation_time() {
    local domain="$1" snap="$2"
    kvm_virsh snapshot-list "$domain" 2>/dev/null | awk -v s="$snap" '
        NR > 2 && $1 == s {
            out = $2
            for (i = 3; i < NF; i++) out = out " " $i
            print out
            exit
        }
    '
}

# 上级快照名
kvm_snapshot_parent() {
    local domain="$1" snap="$2" p
    p=$(kvm_virsh snapshot-info "$domain" "$snap" 2>/dev/null | awk -F'[:：]' '
        /Parent|上级/ {
            gsub(/^[ \t]+|[ \t]+$/, "", $2)
            if ($2 != "" && $2 != "-") print $2
            exit
        }
    ')
    echo "${p:--}"
}

kvm_snapshot_exists() {
    local domain="$1" name="$2"
    kvm_virsh snapshot-info "$domain" "$name" &>/dev/null
}

# 默认快照名
kvm_snapshot_default_name() {
    date +"snap-%Y%m%d-%H%M%S"
}

# 校验快照名称
kvm_snapshot_validate_name() {
    local name="$1"
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || \
        kvm_die "快照名仅允许字母、数字及 ._- ：$name"
}

# 检查磁盘是否适合 libvirt 快照（qcow2 最佳）
kvm_snapshot_check_disks() {
    local domain="$1"
    local path fmt missing=0 unsupported=0
    if ! command -v qemu-img &>/dev/null; then
        kvm_warn "未安装 qemu-img，跳过磁盘格式检查（建议: sudo apt install qemu-utils）"
        return 0
    fi
    while IFS= read -r path; do
        [ -n "$path" ] || continue
        [[ "$path" == \[volume:* ]] && continue
        if [ ! -e "$path" ]; then
            kvm_warn "磁盘不存在: $path"
            ((missing++)) || true
            continue
        fi
        fmt=$(qemu-img info "$path" 2>/dev/null | awk -F: '/file format/ { gsub(/^[ \t]+/, "", $2); print $2; exit }')
        if [ "$fmt" != "qcow2" ]; then
            kvm_warn "磁盘格式「${fmt:-未知}」可能不支持 libvirt 在线快照: $path"
            ((unsupported++)) || true
        fi
    done < <(kvm_domain_disk_paths "$domain")
    [ "$missing" -eq 0 ] || kvm_die "存在缺失磁盘，无法创建快照"
    [ "$unsupported" -eq 0 ] || kvm_warn "非 qcow2 磁盘创建快照可能失败，建议改用 qcow2 或在关机后操作"
}

# 交互选择快照；有参数则校验/前缀匹配
kvm_resolve_snapshot() {
    local domain="$1"
    local arg="${2:-}"

    if [ -n "$arg" ]; then
        if kvm_snapshot_exists "$domain" "$arg"; then
            echo "$arg"
            return
        fi
        local -a matches=()
        local s
        while IFS= read -r s; do
            [ -n "$s" ] && matches+=("$s")
        done < <(kvm_snapshot_names "$domain" | grep -F -- "$arg" || true)
        if [ "${#matches[@]}" -eq 1 ]; then
            echo "${matches[0]}"
            return
        fi
        if [ "${#matches[@]}" -gt 1 ]; then
            kvm_warn "快照名 \"$arg\" 匹配多个：" >&2
            printf '  - %s\n' "${matches[@]}" >&2
            kvm_die "请指定更完整的快照名"
        fi
        kvm_die "快照不存在: $arg"
    fi

    if [ ! -t 0 ]; then
        kvm_die "未指定快照名"
    fi

    local -a snaps=()
    mapfile -t snaps < <(kvm_snapshot_names "$domain")
    if [ "${#snaps[@]}" -eq 0 ]; then
        kvm_warn "虚拟机 $domain 没有任何快照" >&2
        return 1
    fi

    echo "可选快照：" >&2
    local i=1 s cur desc desc_show
    for s in "${snaps[@]}"; do
        cur=""
        kvm_snapshot_is_current "$domain" "$s" && cur=" *当前*"
        desc=$(kvm_snapshot_description "$domain" "$s")
        if [ -n "$desc" ]; then
            desc_show=" — ${desc}"
            [ "${#desc_show}" -gt 48 ] && desc_show="${desc_show:0:45}..."
        else
            desc_show=""
        fi
        printf "  %2d) %s%s%s\n" "$i" "$s" "$cur" "$desc_show" >&2
        ((i++)) || true
    done
    echo -n "请输入序号或名称（空回车取消）: " >&2
    read -r choice || true
    if [ -z "$choice" ]; then
        kvm_warn "已取消" >&2
        return 1
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#snaps[@]}" ]; then
        echo "${snaps[$((choice - 1))]}"
        return 0
    fi
    if kvm_snapshot_exists "$domain" "$choice"; then
        echo "$choice"
        return 0
    fi
    kvm_warn "无效选择: $choice" >&2
    return 1
}

# ---------- 存储池 ----------

kvm_pool_names() {
    kvm_virsh pool-list --all --name 2>/dev/null | sed '/^$/d'
}

kvm_pool_path() {
    local pool="$1"
    kvm_virsh pool-dumpxml "$pool" 2>/dev/null | awk '
        /<path>/ { split($0, a, ">"); split(a[2], b, "<"); print b[1]; exit }
    '
}

kvm_pool_is_active() {
    local pool="$1" state
    # pool-list 更可靠（pool-info 中文状态常为「运行」而非「活动」）
    state=$(kvm_virsh pool-list 2>/dev/null | awk -v p="$pool" '$1 == p { print $2; exit }')
    if [ -n "$state" ]; then
        [[ "$state" == "active" || "$state" == "活动" || "$state" == "running" || "$state" == "运行" ]]
        return
    fi
    state=$(kvm_virsh pool-info "$pool" 2>/dev/null | awk -F'[:：]' '
        /State|状态/ {
            gsub(/^[ \t]+|[ \t]+$/, "", $2)
            print $2
            exit
        }
    ')
    [[ "$state" == "running" || "$state" == "运行" || "$state" == "active" || "$state" == "活动" ]]
}

kvm_pool_capacity_gib() {
    local pool="$1" field="$2"
    kvm_virsh pool-info "$pool" 2>/dev/null | awk -v want="$field" '
        /Capacity|容量/ && want == "cap" {
            if (match($0, /[0-9]+(\.[0-9]+)?/)) { v=substr($0,RSTART,RLENGTH); if (index($0,"TiB")) v=v*1024; print v; exit }
        }
        /Allocation|分配/ && want == "alloc" {
            if (match($0, /[0-9]+(\.[0-9]+)?/)) { v=substr($0,RSTART,RLENGTH); if (index($0,"TiB")) v=v*1024; print v; exit }
        }
        /Available|可用/ && want == "avail" {
            if (match($0, /[0-9]+(\.[0-9]+)?/)) { v=substr($0,RSTART,RLENGTH); if (index($0,"TiB")) v=v*1024; print v; exit }
        }
    '
}

kvm_pool_ensure_active() {
    local pool="$1" out
    kvm_virsh pool-info "$pool" &>/dev/null || kvm_die "存储池不存在: $pool"
    if kvm_pool_is_active "$pool"; then
        return 0
    fi
    kvm_info "启动存储池: $pool"
    if out=$(kvm_virsh pool-start "$pool" 2>&1); then
        return 0
    fi
    if echo "$out" | grep -qiE 'already active|已经激活|已经处于活动|处于活动状态|已在运行|already running'; then
        return 0
    fi
    kvm_die "$out"
}

kvm_pool_register_dir() {
    local name="$1" dir="$2"
    [ -d "$dir" ] || kvm_die "目录不存在: $dir"
    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || kvm_die "池名仅允许字母数字及 ._-"
    if kvm_virsh pool-info "$name" &>/dev/null; then
        kvm_die "存储池已存在: $name"
    fi
    kvm_info "注册存储池: $name -> $dir"
    kvm_virsh pool-define-as --name "$name" dir --target "$dir"
    kvm_virsh pool-build "$name"
    kvm_virsh pool-start "$name"
    kvm_virsh pool-autostart "$name"
    kvm_ok "已创建存储池: $name"
}

kvm_pool_pick() {
    local -a pools=()
    mapfile -t pools < <(kvm_pool_names)
    if [ "${#pools[@]}" -eq 0 ]; then
        kvm_die "没有可用存储池"
    fi

    echo "可选存储位置（libvirt 存储池）：" >&2
    local i=1 p path avail
    for p in "${pools[@]}"; do
        path=$(kvm_pool_path "$p")
        avail=$(kvm_pool_capacity_gib "$p" avail)
        if kvm_pool_is_active "$p"; then
            printf "  %2d) %-12s  %-28s  可用:%s GiB  [活动]\n" "$i" "$p" "$path" "${avail:-?}" >&2
        else
            printf "  %2d) %-12s  %-28s  可用:%s GiB  [未启动]\n" "$i" "$p" "$path" "${avail:-?}" >&2
        fi
        ((i++)) || true
    done
    echo "  n) 新建存储池（移动硬盘等目录）" >&2
    echo -n "请选择 [1-${#pools[@]}/n]（空回车取消）: " >&2
    read -r choice || true
    if [ -z "$choice" ]; then
        kvm_warn "已取消" >&2
        return 1
    fi

    if [[ "$choice" =~ ^[Nn]$ ]]; then
        echo -n "目录路径（如 /media/jessie/KVM）: " >&2
        read -r dir
        [ -n "$dir" ] || kvm_die "路径不能为空"
        mkdir -p "$dir" 2>/dev/null || true
        echo -n "存储池名称 [$(basename "$dir")]: " >&2
        read -r p
        p="${p:-$(basename "$dir")}"
        kvm_pool_register_dir "$p" "$dir"
        echo "$p"
        return
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#pools[@]}" ]; then
        echo "${pools[$((choice - 1))]}"
        return
    fi
    local found=0
    for p in "${pools[@]}"; do
        if [ "$p" = "$choice" ]; then
            echo "$p"
            found=1
            break
        fi
    done
    [ "$found" -eq 1 ] && return 0
    kvm_warn "无效选择: $choice" >&2
    return 1
}

kvm_disk_fix_permissions() {
    local disk="$1"
    if getent group libvirt-qemu &>/dev/null; then
        sudo chgrp libvirt-qemu "$disk" 2>/dev/null || true
        sudo chmod 660 "$disk" 2>/dev/null || true
    fi
}

# ---------- 交互菜单 ----------

kvm_require_tty() {
    [ -t 0 ] || kvm_die "请在本机终端无参数运行以进入菜单"
}

kvm_menu_pause() {
    echo
    echo -n "按 Enter 继续当前菜单，输入 q 返回上级: "
    read -r _kvm_menu_ans || true
    if [[ "${_kvm_menu_ans:-}" =~ ^[Qq]$ ]]; then
        return 1
    fi
    return 0
}

kvm_script_dir() {
    echo "$KVM_MANAGER_DIR"
}

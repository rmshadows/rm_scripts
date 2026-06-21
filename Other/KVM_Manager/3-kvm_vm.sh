#!/bin/bash
# 虚拟机电源与生命周期管理

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=kvm_lib.sh
source "$SCRIPT_DIR/kvm_lib.sh"

VM_SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
用法: ${VM_SCRIPT_NAME} [命令] [选项] [虚拟机名称]

电源与生命周期。无参数时进入交互菜单；命令后省略 VM 名时会列出可选虚拟机。

命令:
  start [--view|-v]    启动（--view 启动后打开 virt-viewer）
  console              打开图形界面（Spice/VNC，VM 需已运行）
  shutdown [--force|-f]  优雅关机（无系统盘时建议 --force）
  reboot               重启（运行中 VM）
  destroy              强制断电（需确认）
  status               显示状态
  autostart on|off     设置开机自启

示例:
  ${VM_SCRIPT_NAME}                          # 交互菜单
  ${VM_SCRIPT_NAME} start --view test_disk     # 启动并打开界面
  ${VM_SCRIPT_NAME} console debian13           # 仅打开界面
  ${VM_SCRIPT_NAME} start test                 # 前缀匹配

依赖: sudo apt install virt-viewer

EOF
}

cmd_start() {
    local domain="$1"
    local with_view="${2:-0}"
    local state
    state=$(kvm_domain_state "$domain")
    if kvm_domain_state_is "$state" running; then
        kvm_warn "虚拟机已在运行: $domain"
        [ "$with_view" -eq 1 ] && kvm_open_console "$domain"
        return 0
    fi
    kvm_info "启动: $domain"
    kvm_ensure_domain_networks "$domain"
    kvm_preflight_start_storage "$domain"
    kvm_virsh start "$domain"
    if kvm_wait_state "$domain" running 30; then
        kvm_ok "已启动: $domain"
    else
        kvm_warn "已发送启动命令，但 30 秒内未进入 running 状态"
    fi
    if [ "$with_view" -eq 1 ]; then
        sleep 1
        kvm_open_console "$domain"
    fi
}

cmd_console() {
    local domain="$1"
    kvm_open_console "$domain"
}

cmd_shutdown() {
    local domain="$1"
    local force="${2:-0}"

    kvm_domain_is_running "$domain" || kvm_die "虚拟机未运行: $domain"

    if [ "$force" -eq 1 ]; then
        kvm_warn "强制断电: $domain"
        kvm_domain_force_stop "$domain"
        return
    fi

    if ! kvm_domain_has_guest_os "$domain"; then
        kvm_warn "该 VM 无系统盘，ACPI 优雅关机通常无效（无操作系统响应）"
        if [ -t 0 ]; then
            if kvm_confirm "改用强制断电 (destroy)?"; then
                kvm_domain_force_stop "$domain"
                return
            fi
        else
            kvm_die "请使用: ${VM_SCRIPT_NAME} shutdown --force $domain"
        fi
    fi

    kvm_info "优雅关机: $domain"
    kvm_virsh shutdown "$domain"
    if kvm_wait_state "$domain" "shut off" 60; then
        kvm_ok "已关机: $domain"
        return
    fi

    kvm_warn "60 秒内未能优雅关机（Guest 未响应 ACPI 时常见）"
    if [ -t 0 ] && kvm_confirm "强制断电 (destroy)?"; then
        kvm_domain_force_stop "$domain"
    else
        kvm_info "可执行: ${VM_SCRIPT_NAME} shutdown --force $domain"
    fi
}

cmd_reboot() {
    local domain="$1"
    kvm_domain_is_running "$domain" || kvm_die "虚拟机未运行，无法重启: $domain"
    kvm_info "重启: $domain"
    kvm_virsh reboot "$domain"
    kvm_ok "已发送重启信号: $domain"
}

cmd_destroy() {
    local domain="$1"
    kvm_domain_is_running "$domain" || kvm_die "虚拟机未运行: $domain"
    kvm_warn "destroy 相当于强制断电，可能导致数据丢失"
    kvm_confirm "确认强制关闭 $domain?" || kvm_die "已取消"
    kvm_domain_force_stop "$domain"
}

cmd_status() {
    local domain="$1"
    local state autostart display_uri
    state=$(kvm_domain_state "$domain")
    autostart=$(kvm_virsh dominfo "$domain" 2>/dev/null | awk '
        /Autostart|自动启动/ {
            if (match($0, /(enable|disable|启用|禁用)/)) print substr($0, RSTART, RLENGTH)
        }
    ')
    display_uri=$(kvm_virsh domdisplay "$domain" 2>/dev/null || echo "-")
    kvm_heading "虚拟机: $domain"
    echo "  状态:     $state"
    echo "  自启动:   ${autostart:-?}"
    echo "  显示:     ${display_uri}"
    echo "  连接:     ${KVM_VIRSH_URI:-默认}"
}

cmd_autostart() {
    local domain="$1"
    local mode="$2"
    case "$mode" in
        on|enable|yes|1)
            kvm_virsh autostart "$domain"
            kvm_ok "已启用自启动: $domain"
            ;;
        off|disable|no|0)
            kvm_virsh autostart --disable "$domain"
            kvm_ok "已禁用自启动: $domain"
            ;;
        *)
            kvm_die "autostart 参数应为 on 或 off，收到: $mode"
            ;;
    esac
}

kvm_vm_run() {
    local cmd="$1"
    local domain="$2"
    local with_view="${3:-0}"
    case "$cmd" in
        start)    cmd_start "$domain" "$with_view" ;;
        console)  cmd_console "$domain" ;;
        shutdown) cmd_shutdown "$domain" ;;
        reboot)   cmd_reboot "$domain" ;;
        destroy)  cmd_destroy "$domain" ;;
        status)   cmd_status "$domain" ;;
        *)        kvm_die "未知命令: $cmd" ;;
    esac
}

kvm_vm_interactive() {
    kvm_require_tty
    while true; do
        clear 2>/dev/null || true
        kvm_heading "电源与控制台"
        echo
        echo "  1) 启动并打开界面"
        echo "  2) 启动"
        echo "  3) 打开界面（VM 已运行时）"
        echo "  4) 优雅关机"
        echo "  5) 强制关机（无系统盘时用）"
        echo "  6) 重启"
        echo "  7) 查看状态"
        echo "  8) 强制断电 destroy"
        echo "  9) 开机自启动 on/off"
        echo "  q) 返回上级"
        echo
        echo -n "请选择（空回车返回上级）: "
        read -r choice || true
        echo

        local cmd domain autostart_mode with_view=0 force=0
        case "$choice" in
            1) cmd=start; with_view=1 ;;
            2) cmd=start ;;
            3) cmd=console ;;
            4) cmd=shutdown ;;
            5) cmd=shutdown; force=1 ;;
            6) cmd=reboot ;;
            7) cmd=status ;;
            8) cmd=destroy ;;
            9) cmd=autostart ;;
            ""|q|Q) break ;;
            *)
                kvm_warn "无效选择: $choice"
                sleep 1
                continue
                ;;
        esac

        if [ "$cmd" = "autostart" ]; then
            echo -n "自启动 on 还是 off? [on/off]: "
            read -r autostart_mode || true
            domain=$(kvm_resolve_domain "") || continue
            cmd_autostart "$domain" "$autostart_mode"
        else
            domain=$(kvm_resolve_domain "") || continue
            if [ "$cmd" = "shutdown" ] && [ "$force" -eq 1 ]; then
                cmd_shutdown "$domain" 1
            else
                kvm_vm_run "$cmd" "$domain" "$with_view"
            fi
        fi
        kvm_menu_pause || break
    done
}

main() {
    if [ $# -lt 1 ]; then
        kvm_ensure_config
        kvm_require_virsh
        kvm_vm_interactive
        exit 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        -h|--help|help)
            usage
            exit 0
            ;;
    esac

    kvm_ensure_config
    kvm_require_virsh

    local domain=""
    local autostart_mode=""
    local with_view=0

    case "$cmd" in
        autostart)
            [ $# -ge 1 ] || kvm_die "用法: ${VM_SCRIPT_NAME} autostart on|off [虚拟机]"
            autostart_mode="$1"
            shift
            domain=$(kvm_resolve_domain "${1:-}")
            cmd_autostart "$domain" "$autostart_mode"
            ;;
        start)
            while [ $# -gt 0 ] && [[ "$1" == -* ]]; do
                case "$1" in
                    --view|-v) with_view=1; shift ;;
                    *) kvm_die "未知选项: $1（start 支持 --view / -v）" ;;
                esac
            done
            domain=$(kvm_resolve_domain "${1:-}")
            cmd_start "$domain" "$with_view"
            ;;
        shutdown)
            local force=0
            while [ $# -gt 0 ] && [[ "$1" == -* ]]; do
                case "$1" in
                    --force|-f) force=1; shift ;;
                    *) kvm_die "未知选项: $1（shutdown 支持 --force / -f）" ;;
                esac
            done
            domain=$(kvm_resolve_domain "${1:-}")
            cmd_shutdown "$domain" "$force"
            ;;
        console|view)
            domain=$(kvm_resolve_domain "${1:-}")
            cmd_console "$domain"
            ;;
        reboot|destroy|status)
            domain=$(kvm_resolve_domain "${1:-}")
            kvm_vm_run "$cmd" "$domain"
            ;;
        *)
            kvm_die "未知命令: $cmd（使用 -h 查看帮助）"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

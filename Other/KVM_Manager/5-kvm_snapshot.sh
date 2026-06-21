#!/bin/bash
# KVM 虚拟机快照：列出 / 创建 / 恢复 / 删除

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=kvm_lib.sh
source "$SCRIPT_DIR/kvm_lib.sh"

SNAP_SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
用法: ${SNAP_SCRIPT_NAME} [命令] [选项] [虚拟机] [快照名]

快照管理（基于 libvirt/virsh，依赖 qcow2 磁盘效果最佳）。

命令:
  list [VM]                   列出快照
  info [VM] [SNAP]            快照详情
  create [VM] [SNAP] [选项]   创建快照
  revert [VM] [SNAP] [选项]   恢复到快照（需确认，建议先关机）
  delete [VM] [SNAP] [选项]   删除快照（需确认）

create 选项:
  --desc TEXT     描述
  --live          运行中 VM 创建在线快照（需 qcow2）
  --quiesce       借助 guest-agent 静默文件系统（需 VM 内安装 agent）

revert 选项:
  --force         未关机时强制恢复（可能损坏数据）

delete 选项:
  --children      同时删除子快照

示例:
  ${SNAP_SCRIPT_NAME}                          # 交互菜单
  ${SNAP_SCRIPT_NAME} list debian11
  ${SNAP_SCRIPT_NAME} create debian11 before-upgrade --desc "升级前"
  ${SNAP_SCRIPT_NAME} revert debian13 snapshot1
  ${SNAP_SCRIPT_NAME} delete debian13 old-snap

EOF
}

cmd_list() {
    local domain="$1"
    kvm_heading "快照: $domain"
    echo

    local -a snaps=()
    mapfile -t snaps < <(kvm_snapshot_names "$domain")
    if [ "${#snaps[@]}" -eq 0 ]; then
        echo "  （无快照）"
        echo
        kvm_info "创建时可加描述: ${SNAP_SCRIPT_NAME} create $domain 名称 --desc \"说明文字\""
        return
    fi

    printf "  %-22s  %-26s  %-6s  %-8s  %s\n" "名称" "生成时间" "当前" "上级" "描述"
    printf "  %s\n" "$(printf '%.0s-' {1..88})"

    local snap when cur parent desc desc_show
    for snap in "${snaps[@]}"; do
        when=$(kvm_snapshot_creation_time "$domain" "$snap")
        [ -n "$when" ] || when="-"
        if kvm_snapshot_is_current "$domain" "$snap"; then
            cur="*"
        else
            cur="-"
        fi
        parent=$(kvm_snapshot_parent "$domain" "$snap")
        desc=$(kvm_snapshot_description "$domain" "$snap")
        if [ -z "$desc" ]; then
            desc_show="（无）"
        else
            desc_show="$desc"
            [ "${#desc_show}" -gt 36 ] && desc_show="${desc_show:0:33}..."
        fi
        printf "  %-22s  %-26s  %-6s  %-8s  %s\n" "$snap" "$when" "$cur" "$parent" "$desc_show"
    done

    echo
    local tree
    tree=$(kvm_virsh snapshot-list "$domain" --tree 2>/dev/null | sed '/^$/d' | tail -n +1)
    if [ -n "$tree" ] && [ "$(echo "$tree" | wc -l)" -gt 1 ]; then
        kvm_info "层级关系:"
        echo "$tree" | sed 's/^/  /'
        echo
    fi

    kvm_info "共 ${#snaps[@]} 个快照（* = 当前位置）"
    kvm_info "详情: ${SNAP_SCRIPT_NAME} info $domain <快照名>"
}

cmd_info() {
    local domain="$1" snap="$2"
    local desc
    desc=$(kvm_snapshot_description "$domain" "$snap")

    kvm_heading "快照详情: $domain / $snap"
    echo
    if [ -n "$desc" ]; then
        echo "  描述:     $desc"
        echo
    fi
    kvm_virsh snapshot-info "$domain" "$snap"
    echo
    if [ -z "$desc" ]; then
        kvm_info "该快照未设置描述（创建时可用 --desc \"说明\"）"
        echo
    fi
    kvm_virsh snapshot-dumpxml "$domain" "$snap" 2>/dev/null | head -25 || true
}

cmd_create() {
    local domain="$1" snap="$2" desc="" live=0 quiesce=0

    shift 2 || true
    while [ $# -gt 0 ]; do
        case "$1" in
            --desc) desc="$2"; shift 2 ;;
            --live) live=1; shift ;;
            --quiesce) quiesce=1; shift ;;
            *) kvm_die "未知选项: $1" ;;
        esac
    done

    [ -n "$snap" ] || snap=$(kvm_snapshot_default_name)
    kvm_snapshot_validate_name "$snap"
    kvm_snapshot_exists "$domain" "$snap" && kvm_die "快照已存在: $snap"

    kvm_snapshot_check_disks "$domain"

    local -a virsh_args=(snapshot-create-as "$domain" "$snap")
    [ -n "$desc" ] && virsh_args+=(--description "$desc")

    if kvm_domain_is_running "$domain"; then
        if [ "$live" -eq 1 ]; then
            virsh_args+=(--live --atomic)
            [ "$quiesce" -eq 1 ] && virsh_args+=(--quiesce)
            kvm_warn "在线快照: $domain（运行中）"
        else
            kvm_warn "虚拟机正在运行。离线快照更一致，建议先关机或使用 --live"
            if [ -t 0 ]; then
                kvm_confirm "仍创建在线快照 (--live)?" || kvm_die "已取消"
                virsh_args+=(--live --atomic)
            else
                kvm_die "运行中 VM 请使用 --live，或先关机"
            fi
        fi
    else
        [ "$quiesce" -eq 1 ] && kvm_warn "VM 已关机，--quiesce 无效"
    fi

    kvm_info "创建快照: $snap"
    kvm_virsh "${virsh_args[@]}"
    kvm_ok "已创建: $snap"
    echo
    cmd_list "$domain"
}

cmd_revert() {
    local domain="$1" snap="$2" force=0

    shift 2 || true
    while [ $# -gt 0 ]; do
        case "$1" in
            --force|-f) force=1; shift ;;
            *) kvm_die "未知选项: $1" ;;
        esac
    done

    kvm_warn "恢复快照将丢失当前磁盘状态（自上次快照以来的变更）"
    if kvm_domain_is_running "$domain"; then
        if [ "$force" -eq 1 ]; then
            kvm_warn "VM 仍在运行，将使用 --force 恢复（高风险）"
        else
            kvm_die "请先关机: ./3-kvm_vm.sh shutdown $domain；或 revert --force（不推荐）"
        fi
    fi

    kvm_confirm "确认恢复到快照 $snap?" || kvm_die "已取消"

    local -a virsh_args=(snapshot-revert "$domain" "$snap")
    [ "$force" -eq 1 ] && virsh_args+=(--force)

    kvm_info "恢复快照: $snap"
    kvm_virsh "${virsh_args[@]}"
    kvm_ok "已恢复到: $snap"
}

cmd_delete() {
    local domain="$1" snap="$2" children=0

    shift 2 || true
    while [ $# -gt 0 ]; do
        case "$1" in
            --children) children=1; shift ;;
            *) kvm_die "未知选项: $1" ;;
        esac
    done

    kvm_warn "将删除快照: $snap（不可恢复）"
    kvm_confirm "确认删除?" || kvm_die "已取消"

    local -a virsh_args=(snapshot-delete "$domain" "$snap")
    [ "$children" -eq 1 ] && virsh_args+=(--children)

    kvm_virsh "${virsh_args[@]}"
    kvm_ok "已删除: $snap"
    echo
    cmd_list "$domain"
}

kvm_snap_interactive() {
    kvm_require_tty
    while true; do
        clear 2>/dev/null || true
        kvm_heading "快照管理"
        echo
        echo "  1) 列出快照"
        echo "  2) 创建快照"
        echo "  3) 恢复快照（建议先关机）"
        echo "  4) 删除快照"
        echo "  5) 快照详情"
        echo "  q) 返回上级"
        echo
        echo -n "请选择（空回车返回上级）: "
        read -r choice || true
        echo

        local cmd domain snap desc
        case "$choice" in
            1) cmd=list ;;
            2) cmd=create ;;
            3) cmd=revert ;;
            4) cmd=delete ;;
            5) cmd=info ;;
            ""|q|Q) break ;;
            *)
                kvm_warn "无效选择: $choice"
                sleep 1
                continue
                ;;
        esac

        domain=$(kvm_resolve_domain "") || continue

        case "$cmd" in
            list)
                cmd_list "$domain"
                ;;
            create)
                echo -n "快照名称 [回车=自动生成]: "
                read -r snap
                echo -n "描述（可选）: "
                read -r desc
                if [ -n "$desc" ]; then
                    cmd_create "$domain" "$snap" --desc "$desc"
                else
                    cmd_create "$domain" "$snap"
                fi
                ;;
            info|revert|delete)
                snap=$(kvm_resolve_snapshot "$domain" "") || continue
                case "$cmd" in
                    info)   cmd_info "$domain" "$snap" ;;
                    revert) cmd_revert "$domain" "$snap" ;;
                    delete) cmd_delete "$domain" "$snap" ;;
                esac
                ;;
        esac
        kvm_menu_pause || break
    done
}

main() {
    if [ $# -lt 1 ]; then
        kvm_ensure_config
        kvm_require_virsh
        kvm_snap_interactive
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

    local domain="" snap=""

    case "$cmd" in
        list)
            cmd_list "$(kvm_resolve_domain "${1:-}")"
            ;;
        info)
            domain=$(kvm_resolve_domain "${1:-}")
            shift
            snap=$(kvm_resolve_snapshot "$domain" "${1:-}")
            cmd_info "$domain" "$snap"
            ;;
        create)
            domain=$(kvm_resolve_domain "${1:-}")
            shift
            snap=""
            if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
                snap="$1"
                shift
            fi
            cmd_create "$domain" "$snap" "$@"
            ;;
        revert)
            domain=$(kvm_resolve_domain "${1:-}")
            shift
            snap=$(kvm_resolve_snapshot "$domain" "${1:-}")
            shift || true
            cmd_revert "$domain" "$snap" "$@"
            ;;
        delete)
            domain=$(kvm_resolve_domain "${1:-}")
            shift
            snap=$(kvm_resolve_snapshot "$domain" "${1:-}")
            shift || true
            cmd_delete "$domain" "$snap" "$@"
            ;;
        *)
            kvm_die "未知命令: $cmd（使用 -h 查看帮助）"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

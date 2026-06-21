#!/bin/bash
# VM 共享文件夹（9p virtio-fs mount）查看与配置

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=kvm_lib.sh
source "$SCRIPT_DIR/kvm_lib.sh"

usage() {
    cat <<'EOF'
用法: kvm_share.sh <命令> [参数...]

管理 VM 的 host 目录共享（libvirt filesystem type=mount / 9p）。
Guest 内需挂载 tag（如 Share、VMShare），本脚本只改 libvirt 配置。

命令:
  list [VM]                         列出共享目录
  add [VM] <宿主机路径> <Guest标签>  添加共享（需 VM 已关机）
  remove [VM] <Guest标签>           移除共享（需 VM 已关机）
  guide [VM]                        打印 Linux Guest 挂载与剪贴板命令
  spice [VM]                        为 VM 启用 Spice 剪贴板通道（需已关机）

示例:
  kvm_share.sh list win10-dev
  kvm_share.sh add debian13 /home/jessie/VM_Share/FTR Share
  kvm_share.sh guide debian13
  kvm_share.sh spice debian-kde
  kvm_share.sh remove debian13 Share

EOF
}

# 解析 dumpxml 中的 filesystem，输出: tag|host_path|mode
kvm_share_parse_filesystems() {
    local domain="$1"
    kvm_virsh dumpxml "$domain" | awk '
        /<filesystem / { tag=""; dir=""; mode=""; in_fs=1 }
        in_fs {
            if (/accessmode=/) {
                sub(/.*accessmode='"'"'/, "")
                sub(/'"'"'.*/, "")
                mode=$0
            }
            if (/<source dir='"'"'/) { split($0, a, "'\''"); dir=a[2] }
            if (/<target dir='"'"'/) { split($0, a, "'\''"); tag=a[2] }
        }
        in_fs && /<\/filesystem>/ {
            if (tag != "") print tag "|" dir "|" mode
            in_fs=0
        }
    '
}

cmd_guest_guide() {
    local domain="$1"
    local -a tags=() paths=() modes=()
    local line tag path mode mount_pt

    kvm_heading "Linux Guest 指南: $domain"
    echo

    while IFS= read -r line; do
        [ -n "$line" ] || continue
        IFS='|' read -r tag path mode <<< "$line"
        tags+=("$tag")
        paths+=("$path")
        modes+=("$mode")
    done < <(kvm_share_parse_filesystems "$domain")

    if [ "${#tags[@]}" -gt 0 ]; then
        kvm_heading "1) 9p 共享目录挂载"
        echo "  在 Guest 里执行的 tag 名称必须与下表「Guest标签」完全一致。"
        echo
        local i
        for i in "${!tags[@]}"; do
            tag="${tags[$i]}"
            path="${paths[$i]}"
            mode="${modes[$i]}"
            mount_pt="/mnt/${tag}"
            echo "  ── 标签 ${tag} ──"
            echo "  宿主机路径: ${path}"
            echo "  访问模式:   ${mode:-passthrough}"
            echo
            echo "  # 加载模块（多数 Debian 已内置，失败再装 linux-modules-extra）"
            echo "  sudo modprobe 9pnet_virtio"
            echo
            echo "  # 一次性挂载"
            echo "  sudo mkdir -p ${mount_pt}"
            echo "  sudo mount -t 9p -o trans=virtio,version=9p2000.L,rw ${tag} ${mount_pt}"
            echo
            echo "  # 验证"
            echo "  mount | grep 9p"
            echo "  ls -la ${mount_pt}"
            echo
            echo "  # 开机自动挂载（写入 /etc/fstab）"
            echo "  ${tag}  ${mount_pt}  9p  trans=virtio,version=9p2000.L,rw,_netdev  0  0"
            echo
        done
    else
        kvm_warn "该 VM 尚未配置 9p 共享目录"
        echo "  先用本脚本 add，或总菜单 5) 共享文件夹 → 2) 添加"
        echo
    fi

    kvm_heading "2) Spice 剪贴板（宿主机 ↔ Guest 复制粘贴）"
    echo "  宿主机: 必须用 virt-viewer 连接（总菜单 → 2) 电源 → 1) 启动并打开界面）"
    echo "          不要用纯 VNC 客户端。"
    echo
    echo "  Guest 内（Debian / Ubuntu）:"
    echo "  sudo apt update"
    echo "  sudo apt install spice-vdagent"
    echo "  sudo systemctl enable --now spice-vdagent"
    echo "  # 安装后重启 VM 或重新登录桌面"
    echo
    local xml has_spice_channel=0 has_spice_gfx=0
    xml=$(kvm_virsh dumpxml "$domain")
    echo "$xml" | grep -q "com.redhat.spice.0" && has_spice_channel=1
    echo "$xml" | grep -q "type='spice'" && has_spice_gfx=1
    if [ "$has_spice_channel" -eq 1 ] && [ "$has_spice_gfx" -eq 1 ]; then
        kvm_ok "XML 已含 Spice 剪贴板通道"
    else
        kvm_warn "XML 缺少 Spice 剪贴板配置（channel spicevmc 或 graphics spice）"
        echo "  宿主机执行: sudo ./4-kvm_share.sh spice ${domain}"
        echo "  或总菜单 → 5) 共享 → 5) 启用 Spice 剪贴板"
    fi
    echo
    kvm_info "Windows Guest: 共享盘需安装 VirtIO 9p 驱动；剪贴板随 Spice 通道自动可用"
}

cmd_spice_enable() {
    local domain="$1"
    kvm_require_shutoff "$domain"

    local xml tmp changed=0
    xml=$(kvm_virsh dumpxml "$domain")

    if ! echo "$xml" | grep -q "type='spice'"; then
        kvm_warn "当前 graphics 不是 Spice，剪贴板无法通过本功能启用"
        kvm_info "请 virsh edit ${domain} 将 graphics 改为 type='spice'，或用 virt-manager 打开"
        return 1
    fi

    if ! echo "$xml" | grep -q "com.redhat.spice.0"; then
        tmp=$(mktemp)
        cat > "$tmp" <<'EOF'
<channel type='spicevmc'>
  <target type='virtio' name='com.redhat.spice.0'/>
</channel>
EOF
        kvm_info "添加 Spice 剪贴板通道…"
        kvm_virsh attach-device "$domain" "$tmp" --config
        rm -f "$tmp"
        changed=1
    else
        kvm_info "Spice 剪贴板通道已存在"
    fi

    xml=$(kvm_virsh dumpxml "$domain")
    if ! echo "$xml" | grep -q "input type='tablet'"; then
        tmp=$(mktemp)
        cat > "$tmp" <<'EOF'
<input type='tablet' bus='usb'/>
EOF
        kvm_info "添加 USB tablet（改善鼠标与 Spice 协同）…"
        kvm_virsh attach-device "$domain" "$tmp" --config
        rm -f "$tmp"
        changed=1
    fi

    if [ "$changed" -eq 1 ]; then
        kvm_ok "已更新 libvirt 配置，下次启动生效"
    else
        kvm_ok "无需修改"
    fi
    echo
    cmd_guest_guide "$domain"
}

cmd_list() {
    local domain="$1"
    kvm_heading "共享文件夹: $domain"
    echo
    local xml
    xml=$(kvm_virsh dumpxml "$domain")
    if ! echo "$xml" | grep -q "<filesystem"; then
        echo "  （无共享目录）"
        echo
        kvm_info "Linux 挂载 / 剪贴板: sudo ./4-kvm_share.sh guide $domain"
        return
    fi
    printf "  %-20s  %-40s  %s\n" "Guest标签" "宿主机路径" "访问模式"
    printf "  %s\n" "$(printf '%.0s-' {1..72})"
    echo "$xml" | awk '
        /<filesystem / { tag=""; dir=""; mode=""; in_fs=1 }
        in_fs {
            if (/accessmode=/) {
                sub(/.*accessmode='"'"'/, "")
                sub(/'"'"'.*/, "")
                mode=$0
            }
            if (/<source dir='"'"'/) { split($0, a, "'\''"); dir=a[2] }
            if (/<target dir='"'"'/) { split($0, a, "'\''"); tag=a[2] }
        }
        in_fs && /<\/filesystem>/ {
            printf "  %-20s  %-40s  %s\n", tag, dir, mode
            in_fs=0
        }
    '
    echo
    local tag
    while IFS= read -r tag; do
        [ -n "$tag" ] || continue
        echo "  Linux 挂载: sudo mount -t 9p -o trans=virtio,version=9p2000.L,rw ${tag} /mnt/${tag}"
    done < <(kvm_share_parse_filesystems "$domain" | cut -d'|' -f1)
    echo
    kvm_info "完整命令（含 fstab / 剪贴板）: sudo ./4-kvm_share.sh guide $domain"
}

cmd_add() {
    local domain="$1"
    local host_path="$2"
    local guest_tag="$3"

    kvm_require_shutoff "$domain"
    [ -d "$host_path" ] || kvm_die "宿主机路径不存在或不是目录: $host_path"
    [[ "$guest_tag" =~ ^[A-Za-z0-9._-]+$ ]] || kvm_die "Guest 标签仅允许字母数字及 ._-"

    local xml
    xml=$(kvm_virsh dumpxml "$domain")
    if echo "$xml" | grep -q "<target dir='$guest_tag'"; then
        kvm_die "Guest 标签已存在: $guest_tag"
    fi

    local tmp
    tmp=$(mktemp)
    cat > "$tmp" <<EOF
<filesystem type='mount' accessmode='passthrough'>
  <source dir='$host_path'/>
  <target dir='$guest_tag'/>
</filesystem>
EOF

    kvm_info "添加共享: $host_path -> $guest_tag"
    kvm_virsh attach-device "$domain" "$tmp" --config
    rm -f "$tmp"
    kvm_ok "已添加，下次启动生效"
    echo
    cmd_list "$domain"
    echo
    cmd_guest_guide "$domain"
}

cmd_remove() {
    local domain="$1"
    local guest_tag="$2"

    kvm_require_shutoff "$domain"

    local tmp found=0
    tmp=$(mktemp)
    if kvm_virsh dumpxml "$domain" | awk -v tag="$guest_tag" '
        /<filesystem / { buf=""; tgt=""; in_fs=1 }
        in_fs {
            buf=buf $0 ORS
            if (/<target dir='"'"'/) { split($0, a, "'\''"); tgt=a[2] }
        }
        in_fs && /<\/filesystem>/ {
            if (tgt == tag) { printf "%s", buf; found=1; exit }
            in_fs=0; buf=""
        }
        END { exit !found }
    ' > "$tmp"; then
        found=1
    fi

    if [ "$found" -ne 1 ] || [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        kvm_die "未找到 Guest 标签: $guest_tag"
    fi

    kvm_warn "将移除共享标签: $guest_tag"
    kvm_confirm "确认?" || { rm -f "$tmp"; kvm_die "已取消"; }
    kvm_virsh detach-device "$domain" "$tmp" --config
    rm -f "$tmp"
    kvm_ok "已移除"
    echo
    cmd_list "$domain"
}

menu_interactive() {
    kvm_require_tty
    while true; do
        clear 2>/dev/null || true
        kvm_heading "共享文件夹 (9p)"
        echo
        echo "  1) 查看某 VM 的共享"
        echo "  2) 添加共享目录"
        echo "  3) 移除共享"
        echo "  4) Linux Guest 挂载 / 剪贴板说明"
        echo "  5) 启用 Spice 剪贴板（改 XML，需 VM 已关机）"
        echo "  q) 返回上级"
        echo
        echo -n "请选择（空回车返回上级）: "
        read -r choice || true
        echo

        local domain host_path guest_tag
        case "$choice" in
            1)
                domain=$(kvm_resolve_domain "") || continue
                cmd_list "$domain"
                kvm_menu_pause || break
                ;;
            2)
                domain=$(kvm_resolve_domain "") || continue
                echo -n "宿主机目录路径: "
                read -r host_path || true
                echo -n "Guest 标签（如 Share）: "
                read -r guest_tag || true
                cmd_add "$domain" "$host_path" "$guest_tag"
                kvm_menu_pause || break
                ;;
            3)
                domain=$(kvm_resolve_domain "") || continue
                echo -n "Guest 标签: "
                read -r guest_tag || true
                cmd_remove "$domain" "$guest_tag"
                kvm_menu_pause || break
                ;;
            4)
                domain=$(kvm_resolve_domain "") || continue
                cmd_guest_guide "$domain"
                kvm_menu_pause || break
                ;;
            5)
                domain=$(kvm_resolve_domain "") || continue
                cmd_spice_enable "$domain" || true
                kvm_menu_pause || break
                ;;
            ""|q|Q)
                break
                ;;
            *)
                kvm_warn "无效选择: $choice"
                sleep 1
                ;;
        esac
    done
}

main() {
    if [ $# -lt 1 ]; then
        kvm_ensure_config
        kvm_require_virsh
        menu_interactive
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

    local domain host_path guest_tag

    case "$cmd" in
        list)
            cmd_list "$(kvm_resolve_domain "${1:-}")"
            ;;
        add)
            domain=$(kvm_resolve_domain "${1:-}")
            shift
            [ $# -ge 2 ] || kvm_die "用法: kvm_share.sh add [VM] <宿主机路径> <Guest标签>"
            cmd_add "$domain" "$1" "$2"
            ;;
        remove)
            domain=$(kvm_resolve_domain "${1:-}")
            shift
            [ $# -ge 1 ] || kvm_die "用法: kvm_share.sh remove [VM] <Guest标签>"
            cmd_remove "$domain" "$1"
            ;;
        guide)
            cmd_guest_guide "$(kvm_resolve_domain "${1:-}")"
            ;;
        spice)
            cmd_spice_enable "$(kvm_resolve_domain "${1:-}")"
            ;;
        *)
            kvm_die "未知命令: $cmd（使用 -h 查看帮助）"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

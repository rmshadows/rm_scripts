#!/bin/bash
# 打开输入法，切换到 Rime，并确保处于中文模式（关闭 ASCII/西文）

set -e

IM_NAME="${FCITX_IM_NAME:-rime}"

_rime_set_chinese() {
    local bus="$1"
    if command -v busctl >/dev/null 2>&1; then
        busctl --user call "$bus" /rime org.fcitx.Fcitx.Rime1 SetAsciiMode b false 2>/dev/null && return 0
    fi
    if command -v dbus-send >/dev/null 2>&1; then
        dbus-send --session --dest="$bus" /rime org.fcitx.Fcitx.Rime1.SetAsciiMode boolean:false >/dev/null 2>&1 && return 0
    fi
    return 1
}

_activate_rime_fcitx5() {
    fcitx5-remote -s "$IM_NAME"
    fcitx5-remote -o
    _rime_set_chinese org.fcitx.Fcitx5
}

_activate_rime_fcitx4() {
    fcitx-remote -s "$IM_NAME"
    fcitx-remote -o
    # fcitx4-rime 通常没有 SetAsciiMode；fcitx5 偶见混用同一 D-Bus 名时仍可能成功
    if _rime_set_chinese org.fcitx.Fcitx5 || _rime_set_chinese org.fcitx.Fcitx; then
        return 0
    fi
    # 先切到键盘布局再切回 Rime，利用 schema 的 ascii_mode reset 尽量回到中文
    fcitx-remote -s fcitx-keyboard-us 2>/dev/null || true
    fcitx-remote -s "$IM_NAME"
    fcitx-remote -o
    echo "警告: fcitx4-rime 无 D-Bus 接口，已尝试通过重选 Rime 恢复中文模式" >&2
}

if command -v fcitx5-remote >/dev/null 2>&1 && pgrep -x fcitx5 >/dev/null 2>&1; then
    _activate_rime_fcitx5
elif command -v fcitx-remote >/dev/null 2>&1 && pgrep -x fcitx >/dev/null 2>&1; then
    _activate_rime_fcitx4
else
    echo "错误: 未检测到运行中的 fcitx 或 fcitx5" >&2
    exit 1
fi

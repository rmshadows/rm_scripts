#!/bin/bash
# 一次部署：装缺少的包、拷贝主题、在当前 XFCE 会话里套用并加快捷键。
# 用法：在本目录执行 sudo ./deploy.sh
# 必须从桌面用户 sudo 上来。直接用 root 跑会把面板主目录写成 /root。
# 开关在 config.sh。已经装过的机器再跑一次，只会改正不对的配置。
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
source "$HERE/config.sh"

STATE_NAME=".local/share/go-undercover/deploy.state"

pkg_installed() {
	dpkg-query -W -f '${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

install_packages() {
	local missing=() pkg
	if [[ "${INSTALL_PACKAGES}" != "1" ]]; then
		echo "软件包开关是关的，跳过。"
		return 0
	fi
	for pkg in $PACKAGES; do
		if pkg_installed "$pkg"; then
			echo "已安装  ${pkg}"
		else
			missing+=("$pkg")
		fi
	done
	if [[ ${#missing[@]} -eq 0 ]]; then
		echo "软件包都在，跳过安装。"
		return 0
	fi
	echo "正在安装：${missing[*]}"
	apt-get update
	apt-get install -y "${missing[@]}"
}

files_need_copy() {
	local reasons=() profile py script
	profile=/usr/share/go-undercover/go-undercover-panel-profile.tar.bz
	py=/usr/share/go-undercover/scripts/desktopconfig.py
	script=/usr/bin/go-undercover
	if [[ "${FORCE_FILES}" == "1" ]]; then
		reasons+=("配置要求强制覆盖")
	fi
	if [[ ! -x "$script" || ! -d /usr/share/themes/Windows-10 || ! -d /usr/share/icons/Windows-10-Icons || ! -f "$profile" ]]; then
		reasons+=("尚未安装完整")
	fi
	if [[ -f "$py" ]] && ! grep -q "endswith('.bz')" "$py"; then
		reasons+=("面板备份不认 .tar.bz")
	fi
	if [[ -f "$script" ]] && ! grep -q -- '--repair' "$script"; then
		reasons+=("已安装的切换脚本没有修复逻辑")
	fi
	if [[ -f "$profile" ]]; then
		if ! tar -tjf "$profile" >/dev/null 2>&1; then
			reasons+=("面板备份不是 bzip2")
		elif tar -xjf "$profile" -O panel.txt 2>/dev/null | grep -q "'/root'"; then
			reasons+=("目录菜单指向 /root")
		fi
		if tar -xjf "$profile" -O desktop.txt 2>/dev/null | grep -q 'kali-undercover'; then
			reasons+=("壁纸仍指向 kali-undercover")
		fi
	fi
	if [[ ${#reasons[@]} -eq 0 ]]; then
		return 1
	fi
	echo "重新部署系统文件：${reasons[*]}"
	return 0
}

copy_files() {
	mkdir -p /usr/share/themes /usr/share/icons /usr/share/applications
	rsync -a --delete "$HERE/Windows-10/" /usr/share/themes/Windows-10/
	rsync -a --delete "$HERE/Windows-10-Icons/" /usr/share/icons/Windows-10-Icons/
	rsync -a --delete "$HERE/go-undercover/" /usr/share/go-undercover/
	install -m 755 "$HERE/go-undercover.sh" /usr/bin/go-undercover
	install -m 644 "$HERE/go-undercover.svg" /usr/share/icons/go-undercover.svg
	install -m 644 "$HERE/go-undercover.desktop" /usr/share/applications/go-undercover.desktop
	find /usr/share/themes/Windows-10 /usr/share/icons/Windows-10-Icons /usr/share/go-undercover -type d -exec chmod 755 {} +
	find /usr/share/themes/Windows-10 /usr/share/icons/Windows-10-Icons /usr/share/go-undercover -type f -exec chmod 644 {} +
	chmod 755 /usr/share/go-undercover/scripts/*.py
	if command -v gtk-update-icon-cache >/dev/null 2>&1; then
		gtk-update-icon-cache -f /usr/share/icons/Windows-10-Icons >/dev/null 2>&1 || true
	fi
	if command -v update-desktop-database >/dev/null 2>&1; then
		update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
	fi
	echo "系统文件已写入 /usr。"
}

session_apply() {
	local state="${HOME}/${STATE_NAME}" home_dir
	home_dir=$(dirname "$state")
	mkdir -p "$home_dir"
	if [[ ! -S "/run/user/$(id -u)/bus" ]]; then
		echo "当前没有图形会话。登录 XFCE 后再运行一次 ./deploy.sh，会补上外观和快捷键。"
		return 0
	fi
	if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
		export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
	fi
	if [[ -z "${DISPLAY:-}" ]]; then
		export DISPLAY=:0
	fi
	if [[ "${FIX_PANEL}" == "1" && -x /usr/bin/go-undercover ]]; then
		/usr/bin/go-undercover --repair
	fi
	if [[ "${APPLY_THEME}" == "1" && -x /usr/bin/go-undercover ]]; then
		if [[ -f "${HOME}/.local/share/go-undercover/lock" ]]; then
			echo "Windows 外观已经开着。"
			touch "$state"
		elif [[ -f "$state" ]]; then
			echo "之前套用过，后来已关掉，这次不再自动打开。需要的话执行：go-undercover --enable"
		else
			/usr/bin/go-undercover --enable
			touch "$state"
			echo "已套用 Windows 外观。"
		fi
	fi
	if [[ "${ADD_SHORTCUTS}" == "1" ]]; then
		bash "$HERE/add-shortcuts.sh"
	fi
}

if [[ "${1:-}" == "--session" ]]; then
	session_apply
	exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
	echo "请用 sudo 运行：" >&2
	echo "  sudo ./deploy.sh" >&2
	exit 1
fi

target="${SUDO_USER:-}"
if [[ -z "$target" || "$target" == "root" ]]; then
	echo "请从桌面用户执行：sudo ./deploy.sh" >&2
	echo "直接用 root 跑会把面板主目录写成 /root。" >&2
	exit 1
fi

install_packages
if files_need_copy; then
	copy_files
else
	echo "系统文件已正确，跳过拷贝。"
fi

target_home=$(getent passwd "$target" | cut -d: -f6)
target_uid=$(id -u "$target")
if [[ ! -S "/run/user/${target_uid}/bus" ]]; then
	echo "系统文件已写好。登录 XFCE 后再执行一次 sudo ./deploy.sh，会把面板主目录设为 ${target_home}，并补上外观和快捷键。"
	exit 0
fi

sudo -u "$target" env \
	HOME="$target_home" \
	USER="$target" \
	LOGNAME="$target" \
	DISPLAY="${DISPLAY:-:0}" \
	XAUTHORITY="${target_home}/.Xauthority" \
	XDG_RUNTIME_DIR="/run/user/${target_uid}" \
	DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${target_uid}/bus" \
	bash "$HERE/deploy.sh" --session

echo "部署完成。"

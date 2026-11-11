#!/bin/sh

if [ "$(id -u)" -eq 0 ]; then
	echo "请用桌面用户运行，不要用 root，也不要 sudo go-undercover。" >&2
	echo "面板里目录菜单的主目录会写成当前用户的家目录。用 root 会写成 /root。" >&2
	exit 1
fi

DIR=~/.local/share/go-undercover/
SHARE_DIR=/usr/share/go-undercover/
CONF_FILES=$SHARE_DIR/config/
XFCE4_PANEL_PROFILES=$SHARE_DIR/scripts/xfce4-desktop-profiles.py
GO_UNDERCOVER_PANEL_PROFILE=$SHARE_DIR/go-undercover-panel-profile.tar.bz
USER_PANEL_PROFILE=$DIR/user-panel-profile.tar.bz

mkdir -p $DIR

WALLPAPER=/usr/share/go-undercover/backgrounds/Windows-10.jpg

set_xconf_settings() {
	xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s "$GTK_THEME"
	xfconf-query -c xfwm4 -p /general/theme -n -t string -s "$WM_THEME"
	xfconf-query -c xfwm4 -p /general/button_layout -n -t string -s "$WM_BUTTON_LAYOUT"
	xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s "$ICON_THEME"
	xfconf-query -c xsettings -p /Gtk/CursorThemeName -n -t string -s "$CURSOR_THEME"
	xfconf-query -c xsettings -p /Gtk/FontName -n -t string -s "$FONT"
}

enable_undercover() {
	cat <<-EOF > $DIR/lock
		GTK_THEME="$(xfconf-query -c xsettings -p /Net/ThemeName 2> /dev/null)"
		WM_THEME="$(xfconf-query -c xfwm4 -p /general/theme 2> /dev/null)"
		WM_BUTTON_LAYOUT="$(xfconf-query -c xfwm4 -p /general/button_layout 2> /dev/null)"
		ICON_THEME="$(xfconf-query -c xsettings -p /Net/IconThemeName 2> /dev/null)"
		CURSOR_THEME="$(xfconf-query -c xsettings -p /Gtk/CursorThemeName 2> /dev/null)"
		FONT="$(xfconf-query -c xsettings -p /Gtk/FontName 2> /dev/null)"
	EOF
	GTK_THEME='Windows-10'
	WM_THEME='Windows-10'
	WM_BUTTON_LAYOUT='|HMC'
	ICON_THEME='Windows-10-Icons'
	CURSOR_THEME='Windows-10-Icons'
	FONT='Liberation Sans 11'
	set_xconf_settings
	$XFCE4_PANEL_PROFILES save $USER_PANEL_PROFILE
	$XFCE4_PANEL_PROFILES load $GO_UNDERCOVER_PANEL_PROFILE
	(cd $CONF_FILES && \
		find . -type f -exec sh -c \
			'[ -f ~/.config/"$1" ] && mv ~/.config/"$1" ~/.config/"${1}.undercover"' _ {} \;)
	cp -r $CONF_FILES/* ~/.config/
	[ -f ~/.face ] && mv ~/.face ~/.face.undercover
	printf ': undercover && export PS1='\''C:${PWD//\//\\\\\}> '\''\n' >> ~/.bashrc
	printf ': undercover && export PS1='\''C:${PWD//\//\\\\}> '\''\n' >> ~/.zshrc
	printf ': undercover && new_line_before_prompt=no\n' >> ~/.zshrc
	repair_session
}

disable_undercover() {
	. $DIR/lock
	set_xconf_settings
	$XFCE4_PANEL_PROFILES load $USER_PANEL_PROFILE
	(cd $CONF_FILES && \
		find . -type f -exec rm ~/.config/{} \;)
	find ~/.config -name '*.undercover' -exec sh -c \
		'mv "$1" "$(echo $1 | sed 's/.undercover//')"' _ {} \;
	[ -f ~/.face.undercover ] && mv ~/.face.undercover ~/.face
	rm $DIR/lock
	sed -i -e '/: undercover/d' ~/.bashrc ~/.zshrc
}

# 不切换主题。关掉自动隐藏，把目录菜单主目录写成当前用户的家目录，
# 把仍指向 kali-undercover 的壁纸改到本工具自带的图。
repair_session() {
	if ! command -v xfconf-query >/dev/null 2>&1; then
		echo "没有 xfconf-query，跳过面板检查"
		return 0
	fi
	panels=$(xfconf-query -c xfce4-panel -l 2>/dev/null \
		| sed -n 's|^/panels/\(panel-[0-9][0-9]*\)/.*|\1|p' | sort -u)
	for p in $panels; do
		cur=$(xfconf-query -c xfce4-panel -p "/panels/$p/autohide-behavior" 2>/dev/null || true)
		if [ "$cur" != "0" ]; then
			xfconf-query -c xfce4-panel -p "/panels/$p/autohide-behavior" -n -t uint -s 0
			echo "已关闭面板 $p 的自动隐藏"
		fi
	done
	# 早上那版把目录菜单主目录写成了 /root。这里一律写成当前用户的家目录。
	xfconf-query -c xfce4-panel -l -v 2>/dev/null | while read -r prop val; do
		case "$prop" in
			/plugins/plugin-*) ;;
			*) continue ;;
		esac
		[ "$val" = "directorymenu" ] || continue
		plug=${prop#/plugins/}
		base=$(xfconf-query -c xfce4-panel -p "/plugins/$plug/base-directory" 2>/dev/null || true)
		if [ "$base" != "$HOME" ]; then
			xfconf-query -c xfce4-panel -p "/plugins/$plug/base-directory" -n -t string -s "$HOME"
		fi
		echo "目录菜单主目录：$HOME"
	done
	# 插件名没列出来时，仍把值为 /root 的起始文件夹改掉。
	xfconf-query -c xfce4-panel -l 2>/dev/null | grep '/base-directory$' | while read -r prop; do
		base=$(xfconf-query -c xfce4-panel -p "$prop" 2>/dev/null || true)
		if [ "$base" = "/root" ]; then
			xfconf-query -c xfce4-panel -p "$prop" -n -t string -s "$HOME"
			echo "目录菜单主目录：$HOME"
		fi
	done
	images=$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep 'last-image$' || true)
	for prop in $images; do
		val=$(xfconf-query -c xfce4-desktop -p "$prop" 2>/dev/null || true)
		case "$val" in
			*kali-undercover*)
				xfconf-query -c xfce4-desktop -p "$prop" -n -t string -s "$WALLPAPER"
				echo "壁纸路径已改正"
				;;
		esac
	done
}

usage() {
	echo "用法: go-undercover [--enable|--disable|--repair]" >&2
	echo "  不带参数    在 Windows 外观和原来的外观之间切换" >&2
	echo "  --enable    打开 Windows 外观；已经打开时只检查面板" >&2
	echo "  --disable   恢复打开前的外观" >&2
	echo "  --repair    只检查自动隐藏、目录菜单和壁纸路径" >&2
}

case "${1:-}" in
	--enable)
		if [ -f "$DIR/lock" ]; then
			echo "已经是 Windows 外观，只检查面板。"
			repair_session
		else
			killall xfce4-notifyd 2>/dev/null || true
			enable_undercover
		fi
		;;
	--disable)
		if [ -f "$DIR/lock" ]; then
			killall xfce4-notifyd 2>/dev/null || true
			disable_undercover
			sleep 1
			notify-send -i dialog-information 'Desktop settings restored' 2>/dev/null || true
		else
			echo "当前不是 Windows 外观。"
		fi
		;;
	--repair)
		repair_session
		;;
	"")
		if [ -f "$DIR/lock" ]; then
			killall xfce4-notifyd 2>/dev/null || true
			disable_undercover
			sleep 1
			notify-send -i dialog-information 'Desktop settings restored' 2>/dev/null || true
		else
			killall xfce4-notifyd 2>/dev/null || true
			enable_undercover
		fi
		;;
	*)
		usage
		exit 1
		;;
esac

# Fluxbox 配置模板

> https://fluxbox.org/

一套可部署到 `~/.fluxbox` 的 **通用 Fluxbox 桌面配置模板**，含右键菜单、主题脚本、多屏、场景切换等。  
Fork 后请先看 [Fork 后必改清单](#fork-后必改清单) 与 [配置指南](#配置指南)。

---

## 快速开始

### 新机器首次安装

```bash
cd /path/to/fluxbox

# 1. 安装依赖（需 sudo）
./apt-install.sh

# 2. 部署到 ~/.fluxbox（自动备份旧配置）
./setup/deploy.sh

# 3. 重载或重新登录 Fluxbox 会话
fluxbox-remote reconfigure
# 或菜单：Restart Fluxbox
```

首次部署前可编辑 `setup/Config.sh`：

| 选项 | 说明 | 默认 |
|------|------|------|
| `SET_INSTALL_APT_DEPS` | 部署时顺带跑 `apt-install.sh` | 0 |
| `SET_DEPLOY_GTKRC` | 复制 GTK2 配置到 `~/.gtkrc-2.0` | 0 |
| `SET_BACKUP_BEFORE_DEPLOY` | 部署前备份 `~/.fluxbox` | 1 |

详见 `setup/README.md`。

### 日常更新配置

```bash
# 方式一：在仓库目录
./setup/deploy.sh

# 方式二：菜单
# Fluxbox Settings → Tools → Deploy

# 方式三：已配置 sync.repo.path 时
~/.fluxbox/scripts/tools/fluxbox-sync.sh deploy
```

修改 `menu` / `keys` / `init` 后，一般执行：

```bash
fluxbox-remote reconfigure    # 重载 init、menu
fluxbox-remote reloadkeys     # 仅重载快捷键
fluxbox-remote reloadstyle    # 仅重载主题/overlay
```

---

## 右键菜单指南

桌面空白处 **右键** 打开主菜单。以下为常用项说明。

### Appearance - 外观

#### Themes - 主题（Fluxbox 边框 / 工具栏 / 菜单样式）

| 菜单项 | 作用 |
|--------|------|
| **Ryan Theme - ryan主题** | 应用你的默认主题 |
| **Set Ryan Default - 设为ryan默认** | 把当前主题存为 ryan（以后点 ryan主题 即恢复） |
| **Browse Themes** | 弹窗浏览系统全部主题 |
| **System - 系统自带** | 列表选择 `/usr/share/fluxbox/styles/` 下主题 |

**ryan 主题是什么？**

- 入口文件：`~/.fluxbox/styles/Ryan`（符号链接，指向真实主题）
- `init` 里 `session.styleFile` 固定指向 Ryan
- 随便试系统主题后，点 **ryan主题** 或 **设为ryan默认** 即可回到你的配色

#### Menu size - 菜单字号

只改字号，**不换主题**。写入 `~/.fluxbox/overlay` 的 `*Font:` 行。

- **Size +2 / -2**：步进调节
- **Font-12 ~ Font-26**：指定字号

#### Menu color - 菜单字色

只改菜单文字颜色，**不换 ryan 主题**。同样写入 `overlay`。

| 菜单项 | 作用 |
|--------|------|
| **Restore Ryan - 恢复ryan字色** | 从 ryan 指向的主题读回原色 |
| **Blue / White / Green …** | 预设字色 |
| **Cycle - 轮换** | 在 ryan 与各预设间循环 |

自定义预设：编辑 `~/.fluxbox/config/menu-colors.conf`

#### Color Mode - 亮暗色

**仅影响 GTK 应用**（Firefox、LibreOffice、文件管理器等），**不改变** Fluxbox 窗口主题。

- **Toggle / Light / Dark**：切换 GTK 亮暗色

配置：`~/.fluxbox/config/color-scheme.conf`

#### Theme & Font - GTK主题图标

打开 `lxappearance`，调整 GTK 应用主题与图标（需已安装）。

#### Wallpaper - 壁纸

扫描 `~/.fluxbox/backgrounds/` 下的图片，用 `fbsetbg` 切换桌面背景。

| 菜单项 | 作用 |
|--------|------|
| **Next / Previous** | 按文件名排序切换上一张/下一张 |
| **Random** | 随机 |
| **Choose** | 列表选择（zenity） |
| **Browse file** | 从任意路径选图 |
| **Open folder** | 打开壁纸目录 |

快捷键：`Win + Shift + B` 下一张。

配置：`~/.fluxbox/config/wallpaper.conf`  
状态：`~/.fluxbox/config/wallpaper.current`（`startup` 登录时用 `restore` 恢复）

#### Conky - 桌面小部件

启动/关闭 Conky，调节字号，切换 Altair / Maia / Dziban / Alsafi 主题包。

#### Profiles - 场景

一键切换工作区数量、窗口布局、Conky 等组合。预设见 `profiles/`，可 **Save Current** 保存自定义场景。

---

### Fluxbox Settings - Fluxbox 设置

| 子菜单 | 作用 |
|--------|------|
| **Toggles** | 远程控制、性能模式、工具栏显示器、Slit 开关 |
| **Display** | 多屏：扩展、镜像、仅内屏/外接（自动检测输出名） |
| **Tools** | 部署、同步、生成 apps 规则、日志轮转 |

多屏输出名不对时，编辑 `~/.fluxbox/config/display.conf`：

```bash
INTERNAL=eDP-1
EXTERNAL=DP-1
```

### 根菜单底部（一级菜单）

| 项 | 作用 |
|----|------|
| **Restart Fluxbox** | 重载 Fluxbox |
| **Exit Session** | 注销 |
| **Reboot / Poweroff** | 重启 / 关机（可走确认框，见 `config/power.conf`） |

锁屏在 **System** 子菜单，命令因机器而异，请按需改 `menu` 里对应行。

---

## 主题、字号、字色：三者关系

```
┌─────────────────────────────────────────────────┐
│  ryan 主题 (styles/Ryan → debian-dark 等)        │  ← Fluxbox 视觉主题
│  菜单 System 主题 / 设为ryan默认                  │
├─────────────────────────────────────────────────┤
│  overlay: *Font:                                │  ← 仅字号
│  菜单 Menu size                                 │
├─────────────────────────────────────────────────┤
│  overlay: menu.*.textColor                      │  ← 仅菜单字色
│  菜单 Menu color → 恢复ryan字色                  │
├─────────────────────────────────────────────────┤
│  gsettings / .gtkrc-2.0                         │  ← 仅 GTK 应用
│  菜单 Color Mode                                │
└─────────────────────────────────────────────────┘
```

三者互不影响，可随意组合。

---

## 常用快捷键

| 快捷键 | 功能 |
|--------|------|
| 桌面右键 | 主菜单 |
| `Alt + F1` | 主菜单 |
| `Alt + Tab` | 切换窗口 |
| `Win + Tab` | rofi 窗口列表 |
| `Alt + Shift + 1~4` | 切换工作区 |
| `Win + d` | 显示桌面 |
| `Win + 方向键` | 最大化 / 最小化 / 收起 |
| `Win + Shift + 方向键` | 半屏平铺 |
| `Win + Shift + B` | 下一张壁纸 |
| `Ctrl + Win + 左右` | 屏幕亮度 |
| `Alt + Shift + e` | 文件管理器 |
| `Alt + Shift + r` | Firefox |
| `Alt + q` | 终端 |
| `Print` | scrot 截图 |
| `Alt + Shift + s` | flameshot 截图 |

完整列表见 `keys`。

### 笔记本媒体键（Fn 音量 / 亮度 / 播放）

在 **GNOME** 下由系统守护进程自动处理；换到 **Fluxbox** 后必须在 `keys` 里绑定，本仓库已预置：

| 键 | 功能 |
|----|------|
| 音量 +/- / 静音 | `scripts/media/volume.sh` |
| 亮度 +/- | `scripts/media/brightness.sh`（优先 `brightnessctl`） |
| 播放/暂停/上下曲 | `scripts/media/player.sh`（需 `playerctl`，`keys` 里默认注释） |

```bash
fluxbox-remote reloadkeys    # 更新 keys 后执行
```

亮度仍无效时，加入 `video` 组并重新登录：`sudo usermod -aG video "$USER"`

键名不确定：运行 `xev` 按媒体键查看，修改 `keys` 里 `XF86*` 行。

---

## Fork 后必改清单

克隆本仓库作个人配置时，建议按顺序检查：

| 优先级 | 位置 | 说明 |
|--------|------|------|
| 高 | `startup` | 壁纸路径、输入法、网络托盘、`exec fluxbox -log` |
| 高 | `config/sync.repo.path` | 改成你的仓库绝对路径 |
| 高 | `config/display.conf` | 多屏时 `xrandr` 查输出名 |
| 中 | `init` | 工作区数量/名称、工具栏 `onhead`（单屏改 0）、时钟格式 |
| 中 | `backgrounds/` | 放入壁纸图片；可选改 `config/wallpaper.conf` |
| 中 | `menu` | 锁屏命令、常用应用是否已安装 |
| 中 | `keys` | 启动器/终端路径、媒体键（播放键需取消注释 + `playerctl`） |
| 低 | `apps` | 无标题栏程序加 `[Deco] {NORMAL}` 规则 |
| 低 | `overlay` | 默认字号；字色可用菜单调节 |
| 低 | `setup/Config.sh` | 是否部署 GTK、是否自动 apt |

完成后执行 `./setup/deploy.sh` 并 **Restart Fluxbox**。

---

## 配置指南

以下说明各核心文件的作用与改法。文件顶部均有注释块，可直接打开对照修改。

### 重载方式速查

| 改了什么 | 命令 |
|----------|------|
| `init` / `menu` / `apps` / `windowmenu` | `fluxbox-remote reconfigure` |
| `keys` | `fluxbox-remote reloadkeys` |
| `overlay` / 主题 | `fluxbox-remote reloadstyle` |
| `startup` | Restart Fluxbox 或重新登录 |

---

### init — 主配置

路径：`init` → 部署后 `~/.fluxbox/init`

控制 Fluxbox 全局行为，与具体应用无关。常用项：

| 配置项 | 作用 | 示例 |
|--------|------|------|
| `session.styleFile` | Fluxbox 主题入口 | `~/.fluxbox/styles/Ryan` |
| `session.styleOverlay` | 主题覆盖层 | `~/.fluxbox/overlay` |
| `session.screen0.workspaces` | 工作区数量 | `4` |
| `session.screen0.workspaceNames` | 工作区名称 | 逗号分隔 |
| `session.screen0.toolbar.*` | 工具栏位置、组件、透明度 | `onhead: 0` 单屏主屏 |
| `session.screen0.window.focus.alpha` | 焦点窗口透明度 | `183` |
| `session.screen0.focusModel` | 焦点模式 | `ClickFocus` |
| `session.screen0.strftimeFormat` | 工具栏时钟格式 | 文件内有多组注释示例 |

路径绑定（一般不用改）：

```
session.menuFile      → menu
session.keyFile       → keys
session.appsFile      → apps
session.slitlistFile  → slitlist
```

也可用菜单 **Appearance → Configure** 图形修改部分选项。

---

### overlay — 主题覆盖层

路径：`overlay` → `~/.fluxbox/overlay`

在 **不修改 ryan 主题文件** 的前提下叠加样式。`init` 里 `session.styleOverlay` 指向本文件。

| 内容 | 说明 |
|------|------|
| `background: unset` | 不覆盖主题背景，壁纸由 `startup` 里 `fbsetbg` 管理 |
| `*Font:` | 菜单/工具栏字号；菜单 **Menu size** 会维护此行 |
| `menu.*.textColor` | 菜单字色；**Menu color** 会维护；恢复ryan字色从主题读回 |

手改示例：

```
*Font:                          DejaVu-16:Serif:Condensed
menu.title.textColor:          #1e90ff
menu.frame.textColor:          #7e7e7e
menu.hilite.textColor:         #1e90ff
```

改完：`fluxbox-remote reloadstyle`

---

### apps — 单应用窗口规则

路径：`apps` → `~/.fluxbox/apps`

为特定程序设置装饰、大小、工作区、层级等。

**第一步：查 class 名**

```bash
xprop | grep -E "WM_CLASS|WM_NAME"   # 点击目标窗口
```

输出示例：`WM_CLASS(STRING) = "firefox-esr", "Firefox-esr"` → 用 `class=firefox-esr`。

**第二步：添加规则**

```
[app] (class=firefox-esr)
  [Deco] {NORMAL}       # 显示标题栏（GTK 无装饰时常用）
  [Layer] {NORMAL}
  [Workspace] {2}       # 默认在第 2 工作区
  [Geometry] {1200x800}
  [Alpha] {230}
[end]
```

也可用菜单 **Fluxbox Settings → Tools → Add App Rule** 交互生成。

模板里预置了 fbrun 居中示例；Nautilus/Firefox 等示例默认 **注释**，按需取消注释。

文档：`man fluxbox-apps`

---

### menu — 右键菜单

路径：`menu` → `~/.fluxbox/menu`

```
[submenu] (子菜单名)
  [exec] (显示名) {shell 命令}
  [config] (Configure)    ! 打开 init 图形配置
  [separator]
[end]
```

- 以 `#` 开头的行是注释；本模板大量保留旧菜单项注释，取消注释即可启用
- 脚本菜单项格式：`{~/.fluxbox/scripts/.../xxx.sh}`
- 锁屏在 **System** 子菜单，请按本机环境改命令（`i3lock`、`xfce4-screensaver` 等）

---

### keys — 快捷键

路径：`keys` → `~/.fluxbox/keys`

格式：`修饰键 键名 :动作` 或 `:Exec 命令`

```bash
Mod1 Tab :NextWindow (workspace=[current])   # Alt+Tab
Mod4 d :ShowDesktop                          # Win+d
XF86AudioRaiseVolume :Exec ~/.fluxbox/scripts/media/volume.sh up
```

- `Mod1` = Alt，`Mod4` = Super/Win
- 键名不确定：运行 `xev` 按键查看
- 播放键（`XF86AudioPlay` 等）在文件末尾默认注释，需安装 `playerctl` 后取消注释

---

### startup — 登录自启

路径：`startup` → `~/.fluxbox/startup`

Shell 脚本，Fluxbox 启动前执行。典型内容：

| 块 | 说明 |
|----|------|
| 主题/日志初始化 | 脚本自动处理 |
| `LANG` / `dbus-launch` | 中文与 D-Bus |
| `wallpaper.sh restore` | 恢复上次壁纸（或 `backgrounds/` 第一张） |
| `fcitx5` / `nm-tray` / `lxpolkit` | 输入法、网络、认证代理 |
| `fbautostart` | 读取 `~/.config/autostart/` |
| `exec fluxbox -log` | **必须保留**；最后一行启动 Fluxbox |

壁纸目录 `backgrounds/` 部署时 **不会覆盖**，请自行放入图片。切换见 **Appearance → Wallpaper**。

---

### windowmenu / slitlist

| 文件 | 作用 |
|------|------|
| `windowmenu` | 标题栏右键菜单项（最大化、层、透明度等） |
| `slitlist` | Slit 停靠区小程序列表，每行一条命令 |

Slit 位置在 `init` 的 `session.screen0.slit.*` 配置。

---

### config/*.conf — 脚本配置

详见 [`config/README.md`](config/README.md)。

| 文件 | 用途 |
|------|------|
| `color-scheme.conf` | GTK 亮暗色 |
| `menu-colors.conf` | 菜单字色预设（`名\|色1\|色2\|色3\|色4`） |
| `display.conf` | 多屏输出名 |
| `power.conf` | 关机确认与 sudo |
| `sync.repo.path` | 同步工具用的仓库路径 |

---

## 主要配置文件

| 文件 | 作用 |
|------|------|
| `init` | Fluxbox 主配置（工作区、工具栏、主题路径等） |
| `menu` | 右键菜单 |
| `keys` | 快捷键 |
| `apps` | 单应用窗口规则（标题栏、层级等） |
| `overlay` | 覆盖主题（字号、菜单字色、背景策略） |
| `startup` | 登录后自启（壁纸、托盘、fcitx 等） |
| `windowmenu` | 窗口右键菜单 |
| `slitlist` | Slit 小程序列表 |
| `styles/Ryan` | 你的默认 Fluxbox 主题入口 |
| `config/*.conf` | 亮暗色、字色、多屏、电源等脚本配置 |

壁纸放在 `~/.fluxbox/backgrounds/`（部署时不覆盖）。

---

## 自定义与维护

### 编辑菜单 / 快捷键 / init

菜单：**Fluxbox Settings → Edit Menu / Keys / Init**（默认 `leafpad`，可改成其他编辑器）

或直接用你喜欢的编辑器打开 `~/.fluxbox/` 下对应文件。

### 为无标题栏的 GTK 程序加装饰条

见上文 [apps — 单应用窗口规则](#apps--单应用窗口规则)，或菜单 **Tools → Add App Rule**。

### 解决 GTK 程序没有标题栏（全局）

将 `OtherRes/gtk-display/.gtkrc-2.0` 复制到 `~/.gtkrc-2.0`，或在 `setup/Config.sh` 设 `SET_DEPLOY_GTKRC=1` 后重新部署。

### 用 mmaker 重新生成菜单

```bash
# 安装 menumaker 后
mmaker fluxbox
# 将 backup/menu.insert 中有用的段落合并进新 menu
```

### 仓库与运行目录同步

```bash
# 仓库 → ~/.fluxbox
./setup/deploy.sh

# ~/.fluxbox → 仓库（改完想提交时）
~/.fluxbox/scripts/tools/fluxbox-sync.sh backup
```

`config/sync.repo.path` 记录仓库路径。

---

## 目录结构（简要）

```
fluxbox/
├── setup/          部署脚本（deploy.sh、Config.sh）
├── scripts/        功能脚本（主题、多屏、开关、工具等）
├── config/         脚本可读的配置（见 config/README.md）
├── profiles/       场景预设
├── styles/         自定义主题（Font-*、Ryan）
├── configs/        Conky 配置与主题包
├── backup/         历史备份
├── menu keys init  Fluxbox 核心配置
├── startup overlay apps
├── apt-install.sh  依赖安装
└── OtherRes/       额外资源（gtk-display、menumaker 等）
```

---

## 常见问题

**改了 menu 没反应？**  
执行 `fluxbox-remote reconfigure` 或 **Restart Fluxbox**。

**主题/字色没变？**  
先 `fluxbox-remote reloadstyle`，关掉菜单再重新打开。

**菜单字色恢复不了？**  
点 **Menu color → Restore Ryan - 恢复ryan字色**（会从 ryan 指向的主题读取原色写回 overlay）。

**多屏扩展无效？**  
运行 `xrandr` 查看输出名，修改 `config/display.conf` 后重试 **Display → Extend**。

**脚本菜单项无反应？**  
确认 `~/.fluxbox/scripts/` 下对应 `.sh` 存在且可执行；可重新 `./setup/deploy.sh`。

**媒体键没反应？**  
执行 `fluxbox-remote reloadkeys`；确认 `~/.fluxbox/scripts/media/` 存在且可执行；亮度见上文 `video` 组。

**关机要不要密码？**  
编辑 `~/.fluxbox/config/power.conf` 中 `REQUIRE_CONFIRM`、`REQUIRE_PASSWORD`。

---

## 相关链接

- [Fluxbox 官网](https://fluxbox.org/)
- 部署细节：`setup/README.md`
- 旧版 Debian GNOME 装机脚本备份：`backup/setup-debian-gnome-init/`（与 Fluxbox 无关）

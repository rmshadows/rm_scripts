# Debian_13_GNOME.sh

>Current Version: 0.1.3

## 目录结构

- `0`、`1`等数字文件夹：0表示固定运行的脚本。1，2，3分别对应检查的一、二、三等，里面可能有子配置文件`cfg.sh`，同时还有一个`setup.sh`是运行的脚本。
- `Config.sh`是总配置，`Config_Templates`是配置模板。
- `Debian_13_Bookworm_GNOME_Setup.sh`，程序入口，主要运行的脚本。
- `GlobalVariables.sh`，全局变量，需要填写密码。
- `Lib.sh`脚本函数库。
- `Archive`时归档，从Debian10至今的存档。
- `other`时其他资源文件。

## 使用方法

适用：Debian 13 GNOME

1. 检查是否符合脚本系统要求（Debian 13 GNOME，**普通用户**，不要 root）
2. 配置好`Config.sh`以及数字目录下的`cfg.sh`（如有必要）
3. 补充需要的资源(比如一些个人个性化配置)
4. 在 GNOME 终端运行`Debian_13_GNOME_Setup.sh`。直接跑也可以，**首次必须输入 y**；脚本会先警告（sudo 免密、zsh、raspi-firmware 等）并做必要检查（TTY、缺 ROOT_PASSWD 时先要 root 密码）。直接回车 = 取消。

白霜拼音词库在仓库 `5/RIME_FROST/`（精简离线包，部署时本地拷贝，不访问 GitHub）。`SET_APT_TO_INSTALL_LATER` 是黑名单：从当前 INDEX 挑出的包放到脚本末尾再装（如 apt-listbugs）。

### 失败后续跑

某检查点失败后，直接**再次运行**同一入口脚本即可；默认会跳过已成功的步骤（进度保存在 `.deploy_progress`）。

- `SET_DEPLOY_RESUME=1`（默认）：启用续跑，跳过已完成步骤
- `SET_DEPLOY_RESET=1`：清除进度，强制从头运行
- `SET_DEPLOY_SKIP_CONFIRM=1`（默认）：**仅续跑**时跳过「是否开始」；首次部署仍必须输入 `y`
- `SET_DEPLOY_FULL_LOG=0`（默认）：不套 `script`，直接用真实终端（wireshark / 显示管理器等 debconf 可交互）。设为 `1` 才全文录像（`script -f`）

## 脚本运行流程

### 初始化脚本

1. 加载变量

   ```
   # 加载全局变量
   source "GlobalVariables.sh"
   # 加载全局函数
   source "Lib.sh"
   # 加载配置(在全局变量之后)
   source "Config.sh"
   ```

2. 脚本预执行

   ```
   # 脚本开始
   source "0/0_start.sh"
   # 预执行
   source "0/init.sh"
   ```

- 加载配置文件和函数库等等
- 获取当前用户名
- 首先检查用户是否在`sudo`组中且免密码。如果没有，临时添加`$USER ALL=(ALL)NOPASSWD:ALL`进`/etc/sudoers`文件中(运行结束或者Ctrl+c中断会自动移除)。
- 检查是否在sudo组中
- 是的话检查是否免密码
- 检查是否时GNOME桌面，不是则警告、退出。
- **部署前警告**：列出将改的项目；检测 raspi-firmware；无 sudo 且未设 ROOT_PASSWD 时先要 root 密码。
- 与用户确认执行（首次必须输入 `y`，回车取消）

### 检查点一

- 临时成为免密`sudoer`(必选)。
- 添加用户到`sudo`组。
- 设置用户`sudo`免密码。
- 默认源安装apt-transport-https ca-certificates wget gnupg2 gnupg lsb-release
- 更新源、更新系统。
- 配置unattended-upgrades

### 检查点二

- 替换vim-tiny为vim-full
- 替换Bash为Zsh
- 替换默认的ZSHRC文件
- 添加/usr/sbin到用户的SHELL环境变量
- 替换root用户的SHELL配置
- 安装bash-completion
- 安装zsh-autosuggestions

### 检查点三

- 自定义自己的服务（运行一个shell脚本）
- 配置Nautilus右键菜单以及Data、Project、Vbox-Tra、Prog、Mounted文件夹
- 可选办公脚本（`SET_NAUTILUS_OFFICE=1`）：同步仓库 `Office/` 到 `~/.local/share/nautilus/lib/Office`，并把 `Office/NautilusScripts/Office/` 平铺到 `scripts/` 后执行 `0-NS-init.sh`
- 复制模板文件夹内容，并在家目录打包 `模板备份.tar.gz`（WPS 等可能清空模板，便于恢复）
- 配置启用NetworkManager、安装net-tools
- 设置网卡eth0为热拔插模式以缩短开机时间。如果没有eth0网卡，发出警告、跳过
- 配置GRUB网卡默认命名方式

### 检查点四

- 从APT源安装常用软件（列表在 `4/cfg.sh`，GNOME 扩展说明见 `4/README.md`）

  - `SET_APT_INSTALL_LIST_INDEX=1` 轻量：网络 debug + 编程工具 + 仅 VLC + 实际在用的 7 个扩展和 `extension-prefs`
  - `=2` 日用影音：1 的全部 + GIMP / Kdenlive / OBS / HandBrake / drawing / yt-dlp / gnucash / 刻录等
  - `=3` 自定义：默认空，往 `APT_TO_INSTALL_INDEX_3` 填

- 脚本最后再安装的应用(滞后)

  ```
    - apt-listbugs——apt显示bug信息。注意：阻碍自动安装，请过后手动安装
    - apt-listchanges——apt显示更改。注意：阻碍自动安装，请过后手动安装
  ```

- 安装Python3

  - 配置Python3源为清华大学镜像
  - 配置Python3全局虚拟环境（Debian12中无法直接使用pip了）

- 安装配置Apache2

  - 配置Apache2 共享目录为 /home/HTML(必选)
    - 是否禁用Apache2开机自启

- 安装php-fpm（默认不自启）

- 安装nginx（默认不自启）

- 可选 fmgr 文件共享（`SET_CONFIG_FMGR=1`，且须同时安装 Nginx+PHP）：同步仓库 `fmgr文件传输/` 到 `/home/HTML/fmgr`，写入 `snippets/fmgr.conf` 并 include。不启动服务，自行 `systemctl start php*-fpm nginx`

- 安装配置Git

  - 配置User Email

- 安装配置SSH

- 安装配置npm

  - 安装cnpm
    - 安装hexo
    - 安装nodejs(必选)

- 安装VirtualBox(滞后)

- 安装Anydesk(滞后)

- 安装Typora(滞后)

- 安装sublime text(滞后)

- 安装teamviewer(滞后)

- 安装wps-office(滞后)

- 安装docker-ce(滞后)

- 禁用第三方软件仓库更新(提升apt体验)(滞后)

### 检查点五

- 配置中州韵输入法(fcitx、ibus、fcitx5)
- 写入登录自启（`~/.config/autostart`）与 Wayland 环境（`~/.config/environment.d`）
- 配置 RIME 词库（离线）：0=基础明月拼音 / 1=白霜拼音（仓库内 `5/RIME_FROST/`，约 42MB）

### 检查点六

- 配置SSH Key(新密钥，导入)

### 检查点七(谨慎使用！可能弄坏您的应用程序！)

- 备份原有的dconf配置

- 导入GNOME Terminal的dconf配置
- 导入GNOME 您自定义修改的系统内置快捷键的dconf配置
- 导入GNOME 自定义快捷键的dconf配置
- 导入GNOME 关机快捷键配置(会清空注销的快捷键)
- 导入GNOME 屏幕放大镜配置
- 导入GNOME 电源配置
- 启用副键调整窗口大小（Tweaks 窗口项）
- 固定 4 个工作区（关闭动态工作区）
- 按 `SET_GNOME_EXTENSIONS_ENABLE` 启用扩展，并导入扩展偏好（Dash 左侧、Freon、Impatience 等）

### 检查点八

配置Shorewall防火墙(需要手动启用)

### 脚本收尾

- 滞后安装的软件
- 设置GRUB os-prober
- 设置用户目录所属

## 脚本内置函数（`Lib.sh`）

- `prompt ()`——控制台颜色输出

  ```
  -s:绿色——成功信息
  -x:绿色——日志：{}
  -e:红色——错误
  -w:黄色——警告
  -i:蓝色——一般信息
  -m:蓝色——信息：{}
  -k:蓝色&红色——格式化输出
  ```

- `onSigint`——程序中断处理方法,包含正常退出该执行的代码

- `onExit ()`——正常退出需要执行的

- `quitThis ()`——中途异常退出脚本要执行的 注意，检查点一后才能使用这个方法

- `doAsRoot ()`——以root身份运行

- `checkRootPasswd ()`——检查root密码是否正确

- `comfirm ()`——询问函数 Yes:1 No:2 其他:5。

  ```
  函数调用请使用：
  comfirm "\e[1;33m? [y/N]\e[0m"
  choice=$?
  if [ $choice == 1 ];then
    yes
  elif [ $choice == 2 ];then
    prompt -i "——————————  下一项  ——————————"
  else
    prompt -e "ERROR:未知返回值!"
    exit 5
  fi
  ```

- `backupFile ()`——备份配置文件。先检查是否有bak结尾的备份文件，没有则创建，有则另外覆盖一个newbak文件。$1 :文件名

- `doApt ()`——执行 apt。本机第一次部署会提示 unattended-upgrade 可能占锁（之后写入 `.deploy_apt_hint`，续跑不再提示）

- `addFolder ()`——新建文件夹。只能有一个参数$1

- `log_message_bg() `——后台记录日志。

- `log_message()`——记录日志(会显示再终端) log_message_bg "信息" "日志文件"

- `do_job()`——在当前终端 source 执行步骤（保留 TTY，apt 可交互）；开始/结束写入日志。整次运行可用 `script` 包一层记全文。

- `deploy_*()`——部署进度：`deploy_is_job_done`、`deploy_mark_job_done`、`deploy_reset_state` 等（状态文件 `.deploy_progress`）

- `replace_username()`——替换用户名为使用已定义的 $CURRENT_USER

- `### archive` ——旧函数存档

## 应用列表

完整包名与描述以 `4/cfg.sh` 为准，不要在本文件维护第二份。

- **INDEX 1 轻量**（`Config.sh` 默认）：网络 debug（aircrack / nmap / hydra / tcpdump / wireshark 稍后装 等）、编程工具（build-essential / gcc / cmake / headers）、日常终端与文件、**仅 VLC**、7 个在用扩展 + `gnome-shell-extension-prefs`
- **INDEX 2 日用影音**：INDEX 1 + GIMP / Kdenlive / OBS / HandBrake / drawing / yt-dlp / gnucash / clamav / httrack / 刻录扩展 / grub-customizer / pavucontrol
- **INDEX 3 自定义**：默认空，把需要的行拷进 `APT_TO_INSTALL_INDEX_3`

GNOME 扩展对照表见 `4/README.md`。

## 更新日志

- 2026.09.13——0.1.3
  - nvm：钉版升级 v0.40.7，脚本/文档与 Server 侧统一（删除 NVM_README.md 与旧版 install-nvm-v0.40.1.sh，只留一份 README）
  - 禁用第三方源：改用快照白名单（Lib.sh 新增 deploy_apt_snapshot_keep 等），只挪走检查点一后新增的 sources.list.d
  - Config.sh 订正「禁用第三方源」开关的注释说明

- 2026.09.11——0.1.2
  - 直接跑部署脚本会先警告并做必要检查（TTY / raspi-firmware / root 密码）；首次必须输入 `y`，回车取消
  - 修复 `SET_DOCKER_PURGE_REINSTALL`：仅当为 1 才清除 `/var/lib/docker`（原先 0 才会清）

- 2026年8月29日——0.1.1
  - 失败后续跑（`.deploy_progress`）；apt 交互保留真实 TTY（debconf / wireshark / 显示管理器）
  - 稍后安装改为 INDEX 黑名单；apt-listbugs 等不再提前装上卡死自动安装
  - 白霜拼音精简离线包入库（约 42MB），部署本地拷贝，不 git clone
  - fcitx5 后台启动、登录自启与 `environment.d`；unattended-upgrade 占锁提示仅本机第一次出现

- 2025年10月1日——0.1.0
  - 开始适配Debian 13

- 2025年2月12日——0.0.9
  - 重构优化结构

- 2024年12月26日——0.0.8
  - 新增Shorewall防火墙配置

- 2024年12月13日——0.0.7
  - 重构脚本

- 2023年10月10日——0.0.5
  - 新增Nginx安装（Apache2就不要了）

- 2023年6月29日——0.0.3
  - 修复输入法安装bug
- 2023年6月29日——0.0.2
  - 修复`zsh-autosuggestions`安装的bug
  - 新增Python虚拟环境搭建
  - 增加截屏等组件的失效警告
- 2023年6月23日——0.0.1
  - 从Debian 11迁移到Debian 12
  - 新增步骤GRUB OS_PROBER启用（自Debian 12 开始，GRUB检测其他系统的 os-prober 被禁用了）。
  - fcitx和fcitx5在debian12中无法共存

## 备忘录

```
# 无需密码：
【普通用户的用户名】	ALL=(ALL)NOPASSWD:ALL
# 需要密码：
【普通用户的用户名】	ALL=(ALL:ALL)	ALL
```

# 其他脚本——OtherScripts

- Cancel_All_Print_Task.sh——取消所有打印任务
- GNOME_Lock_Screen.sh——GNOME锁屏

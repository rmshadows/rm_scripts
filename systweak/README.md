# systweak

已有系统上的**单功能开关脚本**：拷哪个用哪个，互不依赖。

与 `Debian_*_Init`（新机全量部署）不同：这里只做微调，并尽量支持**还原到改之前**。

旧目录 `forKylinV10SP1/` 保留作归档；新脚本请用本目录。

## 约定

每个脚本：

```bash
./某脚本.sh              # 默认 --apply：先备份再改
./某脚本.sh --undo       # 按本机备份还原
./某脚本.sh --status     # 查看当前状态（若支持）
./某脚本.sh --help
```

- 备份目录默认：`~/.systweak-backup/<脚本名>/`  
  可用环境变量覆盖：`SYSTWEAK_BACKUP=/其它路径`
- **一个文件拷走即可跑**（不要依赖本仓库其它文件）
- 需要 root 的脚本请用 `sudo`；涉及 `gsettings` 的请在**目标用户图形会话**下执行（或 `sudo -u 用户`）
- `--undo` 只能还原**本脚本留下的备份**；装过的 apt 包默认不自动卸载（避免误伤），说明见各脚本头注释

写新脚本可复制 [`_template.sh`](_template.sh)。

## 脚本列表

| 脚本 | 作用 | 还原能力 |
|------|------|----------|
| `sudo-nopasswd.sh` | 给用户加/撤 sudo 免密（`/etc/sudoers.d/`） | 好（删文件即可） |
| `set-hostname.sh` | 修改系统主机名（同步 `/etc/hostname`、`hosts`） | 好 |
| `enable-sysrq.sh` | 启用 Magic SysRq（默认永久；`--temp` 仅临时） | 好 |
| `setup-shorewall.sh` | 一键部署 Shorewall（需旁路 `shorewall/SW_CONF` 或 `.tar.gz`；默认不自动启动） | 中 |
| `disable-sleep.sh` | 禁止休眠/挂起（systemd mask + GNOME/XFCE） | 中（还原 mask 与 gsettings） |
| `lock-suspend.sh` | 启用或禁用「休眠+锁屏」相关项 | 中（快照 gsettings/logind 等） |
| `gnome-idle-lock.sh` | GNOME：闲置 60s 锁屏、立即锁定 | 好（还原 gsettings） |
| `default-fm-nautilus.sh` | 默认文件管理器改为 Nautilus | 好 |
| `python-env.sh` | Python3 + 清华 pip 源 + 默认 venv（`~/.PythonVenv`）+ shell `acpy`/`decpy` | 中（还原镜像/本脚本建的 venv；包不卸） |
| `setup-zsh.sh` | 安装 zsh/插件，写入 **GNOME Init 同款 zshrc**（已内嵌），root+当前用户切 zsh | 中（还原 shell 与 `.zshrc`；包不卸） |
| `rime-chinese-mode.sh` | 当前会话切到 Rime 中文模式 | 弱（即时操作，无持久备份） |
| `lightdm-gtk-greeter.sh` | LightDM 使用 **lightdm-gtk-greeter**（可设为默认 DM） | 中（还原 conf/默认 DM；包不卸） |
| `lightdm-gtk-background.sh` | 设置 LightDM GTK greeter 背景图 | 好（还原 conf） |
| `wechat-recv-writable.sh` | GNOME：Alt+Shift+M 把微信接收文件目录设为可写（自动发现账号） | 好（还原原快捷键） |
| `_template.sh` | 新脚本模板 | — |

## 示例

```bash
# 只拷一个文件到目标机器
scp systweak/sudo-nopasswd.sh user@host:~/
ssh user@host 'sudo bash sudo-nopasswd.sh'
# 后悔
ssh user@host 'sudo bash sudo-nopasswd.sh --undo'

sudo bash setup-zsh.sh
sudo bash setup-zsh.sh --undo
```

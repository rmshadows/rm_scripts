# HDMI / KVM 切回黑屏恢复

KVM 或 HDMI 热插拔后，系统还在、SSH 也通，但屏幕无画面。已验证有效的做法：

```text
xrandr --output <口> --off
sleep 1
xrandr --output <口> --mode/pos/...   # 有布局
# 或 --auto                             # 无布局
```

本目录把这件事做成：先**记录当前屏幕**，热插拔时 **off → 按记录打开**。不写死 `HDMI-1`、分辨率、用户名。适用于 **X11**：GNOME（登录选 **GNOME on Xorg**）、Xfce、Fluxbox。Wayland 上 xrandr 管不到真实输出。

热插拔自动重置可以随时用配置关掉，**不必卸载**。突然要重置可以手动跑一条命令，**不受该开关影响**。

---

## 本目录文件

| 文件 | 装到 | 作用 |
|---|---|---|
| `99-hdmi-hotplug.rules` | `/etc/udev/rules.d/99-hdmi-hotplug.rules` | DRM `HOTPLUG=1` 时调 trigger |
| `hdmi-hotplug-trigger.sh` | `/usr/local/bin/hdmi-hotplug-trigger.sh` | 读开关；为 1 则 `systemctl start --no-block` |
| `hdmi-hotplug-recover.service` | `/etc/systemd/system/hdmi-hotplug-recover.service` | oneshot，`User=` 桌面用户 |
| `hdmi-hotplug-recover.sh` | `/usr/local/bin/hdmi-hotplug-recover.sh` | 热插拔恢复；`now` = 立刻手动重置 |
| `hdmi-hotplug-save.sh` | `/usr/local/bin/hdmi-hotplug-save.sh` | 画面正常时记录布局；`doctor` 诊断 |
| `hdmi-hotplug-check.sh` | `/usr/local/bin/hdmi-hotplug-check.sh` | 安装前预检：X11 / xrandr / DRM / udev 热插拔 |
| `hdmi-hotplug-lib.sh` | `/usr/local/lib/hdmi-hotplug/hdmi-hotplug-lib.sh` | 探测 X11、读写布局、xrandr |
| `hdmi-hotplug.conf` | `/etc/hdmi-hotplug.conf` | `HDMI_HOTPLUG_RESET=0/1` |
| `setup.sh` | 不拷到系统 | 可选：预检 + 一键安装 + 尽量当场 save |

`recover.service` 里的 `__DESKTOP_USER__` 必须改成你的用户名（`setup.sh` 会自动替换）。

---

## 你需要提供 / 注意什么

一般**不用**填输出名、分辨率、刷新率。

| 项目 | 说明 |
|---|---|
| 桌面用户 | `setup.sh` 默认 `$SUDO_USER`；不对则 `sudo SETUP_USER=alice ./setup.sh`。**手动安装必须**改 service 里的 `__DESKTOP_USER__` |
| 会话 | GNOME 请用 **GNOME on Xorg**。Xfce / Fluxbox 本身是 X11 |
| 依赖 | `xrandr`（Debian：`x11-xserver-utils`） |
| 布局 | setup 会尝试 save；失败则自己在桌面终端跑 `hdmi-hotplug-save.sh` |
| 开关 | 可选。改 `/etc/hdmi-hotplug.conf`，不必卸载 |

---

## 热插拔 vs 手动

```text
HDMI/KVM 热插拔
    → udev 99-hdmi-hotplug.rules
    → trigger.sh
         ├─ HDMI_HOTPLUG_RESET=0  → 立刻退出（不 start、不 xrandr）
         └─ =1 或没有这项
              → systemd hdmi-hotplug-recover.service
              → recover.sh（无参数）
              → 等约 2 秒 → off → 按布局打开

你临时要重置（黑屏、SSH 也行，只要能操作这台机的 X）
    → hdmi-hotplug-recover.sh now
    → 立刻 off → 打开（忽略 HDMI_HOTPLUG_RESET）
```

开关只管 **udev 自动那条路**。`now` 始终会重置。

---

## 预检

静态检查**不能代替**真切一次 KVM。它能确定 X11/xrandr 能不能重置；udev 是否会在切回时报警，只能监听到真实 `HOTPLUG=1` 才算实锤。

```bash
cd systweak/HDMI断线无法重连
./hdmi-hotplug-check.sh                 # 或 ./setup.sh check
./hdmi-hotplug-check.sh --wait-hotplug  # 倒计时内切换一次 KVM
```

| 结果 | 含义 |
|---|---|
| 通过 | 可以安装。X11/`xrandr` 重置预期可用；DRM 节点也在。udev 是否会在 KVM 切回时报警，要用 `--wait-hotplug` 实锤 |
| 警告 | 允许安装。有已知风险（例如没有 `nvidia_drm`、等了热插拔却没有 `HOTPLUG=1`） |
| 失败 | 允许安装，但**可能完全无效**（常见：Wayland、没有 DISPLAY、没有 DRM） |

`sudo ./setup.sh` 会先跑预检：通过则直接装；未通过会说明风险并问一句，答 `y` 仍继续。非交互环境用 `HDMI_HOTPLUG_FORCE=1`；`HDMI_HOTPLUG_SKIP_CHECK=1` 跳过预检。

---

## 用 setup.sh 安装

```bash
cd systweak/HDMI断线无法重连
./setup.sh check                     # 只预检
sudo ./setup.sh                      # 预检 + 安装，并尽量以桌面用户 save
sudo SETUP_USER=alice ./setup.sh
sudo HDMI_HOTPLUG_FORCE=1 ./setup.sh # 预检失败也装
sudo ./setup.sh uninstall            # 不删 conf 和布局文件
```

已有 `/etc/hdmi-hotplug.conf` 时不会覆盖。

---

## 手动安装

```bash
cd systweak/HDMI断线无法重连
sed -i "s/__DESKTOP_USER__/$USER/g" hdmi-hotplug-recover.service   # 或手改

sudo cp 99-hdmi-hotplug.rules /etc/udev/rules.d/
sudo cp hdmi-hotplug-trigger.sh hdmi-hotplug-recover.sh hdmi-hotplug-save.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/hdmi-hotplug-*.sh
sudo mkdir -p /usr/local/lib/hdmi-hotplug
sudo cp hdmi-hotplug-lib.sh /usr/local/lib/hdmi-hotplug/
sudo cp hdmi-hotplug.conf /etc/hdmi-hotplug.conf
sudo cp hdmi-hotplug-recover.service /etc/systemd/system/
sudo udevadm control --reload-rules
sudo systemctl daemon-reload
```

然后在**画面正常的桌面终端**记录布局（手动装时 setup 不会帮你 save）：

```bash
hdmi-hotplug-save.sh
# 或：./hdmi-hotplug-save.sh
```

---

## 日常命令

```bash
# 改过分辨率/多屏之后重新记布局
hdmi-hotplug-save.sh

# 突然黑屏：立刻重置（不受 conf 开关影响）
hdmi-hotplug-recover.sh now

# 诊断 DISPLAY / XAUTHORITY / xrandr / 布局 / 开关
hdmi-hotplug-save.sh doctor

# 预检 X11 / DRM / udev（可加 --wait-hotplug 等一次真切 KVM）
hdmi-hotplug-check.sh

# 关掉热插拔自动重置（udev 仍在，trigger 空跑退出）
sudo sed -i 's/^HDMI_HOTPLUG_RESET=.*/HDMI_HOTPLUG_RESET=0/' /etc/hdmi-hotplug.conf

# 再打开自动重置
sudo sed -i 's/^HDMI_HOTPLUG_RESET=.*/HDMI_HOTPLUG_RESET=1/' /etc/hdmi-hotplug.conf
```

改 conf **立刻生效**，不用 reload udev。

日志：

```bash
journalctl -t hdmi-hotplug -n 30 --no-pager
sudo journalctl -u hdmi-hotplug-recover.service -n 30 --no-pager
```

---

## 布局文件

`hdmi-hotplug-save.sh` 写出当前每个 **connected** 输出的名字、是否主屏、mode、刷新率、位置、旋转。

| 谁执行 save | 写到哪 |
|---|---|
| 普通用户 | `~/.config/hdmi-kvm-fix/layout.conf` |
| root（`sudo save`） | `/var/lib/hdmi-kvm-fix/layout.conf` |

恢复时**先读系统这份，没有再用用户这份**。没有布局则对全部 connected 输出 `--off` 再 `--auto`。记下的 mode 若当前 EDID 没有，会回退 `--auto`。

---

## 开关文件 `/etc/hdmi-hotplug.conf`

```
HDMI_HOTPLUG_RESET=1   # 热插拔时执行 xrandr
HDMI_HOTPLUG_RESET=0   # 停用自动重置，不必卸载
```

`trigger.sh` 和 `recover.sh`（无参数）都会读。`recover.sh now` 不读这项。

---

## 为什么 udev 不直接跑 xrandr

- udev 环境没有桌面的 `DISPLAY` / `XAUTHORITY`，而且不宜 `sleep`。
- 一次拔插可能多个 `HOTPLUG`，需要 systemd + `flock` 去重。

流程：`DRM HOTPLUG` → udev → trigger → systemd oneshot（桌面用户）→ recover.sh。

---

## 背景（原先针对的机器）

HDMI KVM 接两台 Linux：x86 一台、ARM64 海思 `hisi-drm` 一台。ARM 切走再切回后 SSH 正常、HDMI 无画面；对该机 `HDMI-1` 做 off → auto 可恢复。现脚本已推广到任意输出名和分辨率，不依赖 `ryan` / `HDMI-1`。

确认本机是否有 DRM 热插拔（比静态预检更准）：

```bash
./hdmi-hotplug-check.sh --wait-hotplug
# 或：
udevadm monitor --property --subsystem-match=drm
```

切换 KVM，应看到 `SUBSYSTEM=drm`、`ACTION=change`、`HOTPLUG=1`。

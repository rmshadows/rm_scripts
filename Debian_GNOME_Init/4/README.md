# Debian apt 中的 GNOME Shell 扩展

对照仓库：Debian 13（GNOME Shell 48）。`apt-cache search --names-only '^gnome-shell-extension'`。

**安装 ≠ 启用。** INDEX 里装上的扩展只是文件落在 `/usr/share/gnome-shell/extensions/<UUID>/`。要启用请改 `Config.sh` 的 `SET_GNOME_EXTENSIONS_ENABLE`（检查点七写入 `org.gnome.shell enabled-extensions`）。

**互斥：** `dashtodock` 与 `dash-to-panel` 不要同时启用。

## 本仓库默认启用（与当前机器实际在用的一致）

| UUID | apt 包 | 作用 |
|---|---|---|
| `dash-to-dock@micxgx.gmail.com` | `gnome-shell-extension-dashtodock` | 左侧常驻/自动隐藏 Dock |
| `ubuntu-appindicators@ubuntu.com` | `gnome-shell-extension-appindicator` | 顶栏托盘（AppIndicator / 旧式 tray） |
| `drive-menu@gnome-shell-extensions.gcampax.github.com` | `gnome-shell-extension-drive-menu` | 顶栏可移动磁盘菜单 |
| `freon@UshakovVasilii_Github.yahoo.com` | `gnome-shell-extension-freon` | 顶栏温度等传感器（建议装 `lm-sensors`） |
| `harddiskled@bijidroid.gmail.com` | `gnome-shell-extension-hard-disk-led` | 顶栏磁盘读写指示 |
| `impatience@gfxmonk.net` | `gnome-shell-extension-impatience` | 加快 GNOME 动画 |
| `noannoyance-fork@vrba.dev` | `gnome-shell-extension-no-annoyance` | 去掉「窗口已准备就绪」打扰，直接聚焦窗口 |

偏好（Dock 在左、Freon 显示均温/最高温、Impatience `0.25` 等）在 `7/cfg.sh`，由 `SET_GNOME_EXTENSIONS_CONFIG=1` 导入。

剪贴板用 apt 的 **CopyQ**，不再装 `gnome-shell-extension-gpaste`。

---

## 独立扩展包

| 软件包 | UUID（本机或 Debian 常见值） | 作用 |
|---|---|---|
| `gnome-shell-extension-appindicator` | `ubuntu-appindicators@ubuntu.com` | AppIndicator / KStatusNotifier / 旧托盘图标到顶栏 |
| `gnome-shell-extension-apps-menu` | `apps-menu@gnome-shell-extensions.gcampax.github.com` | 顶栏按分类的应用菜单 |
| `gnome-shell-extension-arc-menu` | `arcmenu@arcmenu.com` | 可定制开始菜单（Arc 风格） |
| `gnome-shell-extension-autohidetopbar` | `hidetopbar@mathieu.bidon.ca` | 自动隐藏顶栏 |
| `gnome-shell-extension-auto-move-windows` | `auto-move-windows@gnome-shell-extensions.gcampax.github.com` | 按应用把新窗口丢到指定工作区 |
| `gnome-shell-extension-blur-my-shell` | `blur-my-shell@aunetx` | 概览 / 顶栏 / Dash 模糊 |
| `gnome-shell-extension-caffeine` | `caffeine@patapon.info` | 临时禁止锁屏、息屏、挂起 |
| `gnome-shell-extension-dashtodock` | `dash-to-dock@micxgx.gmail.com` | Dash 变成持久 Dock |
| `gnome-shell-extension-dash-to-panel` | `dash-to-panel@jderose9.github.com` | Dash + 顶栏合成一条任务栏（与 Dock 互斥） |
| `gnome-shell-extension-desktop-icons-ng` | `ding@rastersoft.com` | 桌面图标（DING） |
| `gnome-shell-extension-drive-menu` | `drive-menu@gnome-shell-extensions.gcampax.github.com` | 可移动驱动器菜单 |
| `gnome-shell-extension-easyscreencast` | `EasyScreenCast@iacopodeenosee.gmail.com` | 简易录屏 |
| `gnome-shell-extension-flypie` | `flypie@schneegans.github.com` | 饼状快捷菜单 |
| `gnome-shell-extension-freon` | `freon@UshakovVasilii_Github.yahoo.com` | 温度 / 风扇等传感器 |
| `gnome-shell-extension-gamemode` | `gamemode@christian.kellner.me` | 显示 GameMode 是否在跑 |
| `gnome-shell-extension-gpaste` | `GPaste@gnome-shell-extensions.gnome.org` | GPaste 剪贴板（本仓库改用 CopyQ，INDEX 已去掉） |
| `gnome-shell-extension-gsconnect` | `gsconnect@andyholmes.github.io` | 手机互联（KDE Connect 协议） |
| `gnome-shell-extension-gsconnect-browsers` | （配合 gsconnect） | 浏览器把链接/标签发给手机 |
| `gnome-shell-extension-hamster` | `hamster@projecthamster.wordpress.com` | Hamster 时间追踪（依赖 `hamster-time-tracker`） |
| `gnome-shell-extension-hard-disk-led` | `harddiskled@bijidroid.gmail.com` | 磁盘 I/O 指示 |
| `gnome-shell-extension-hide-activities` | `Hide_Activities@shay.shayel.org` | 隐藏顶栏「活动」按钮 |
| `gnome-shell-extension-impatience` | `impatience@gfxmonk.net` | 加快动画 |
| `gnome-shell-extension-kimpanel` | `kimpanel@kde.org` | fcitx 候选窗 / 托盘（KDE Kimpanel 协议） |
| `gnome-shell-extension-launch-new-instance` | `launch-new-instance@gnome-shell-extensions.gcampax.github.com` | 点击图标总是新开实例 |
| `gnome-shell-extension-light-style` | `light-style@gnome-shell-extensions.gcampax.github.com` | Shell 切到浅色样式 |
| `gnome-shell-extension-native-window-placement` | `native-window-placement@gnome-shell-extensions.gcampax.github.com` | 活动概览里窗口排布更紧 |
| `gnome-shell-extension-no-annoyance` | `noannoyance-fork@vrba.dev` | 去掉「窗口已准备就绪」通知（Debian 13 是 fork） |
| `gnome-shell-extension-places-menu` | `places-menu@gnome-shell-extensions.gcampax.github.com` | 顶栏位置 / 收藏夹菜单 |
| `gnome-shell-extension-runcat` | `runcat@kolesnikov.se` | 用跑步的猫表示 CPU |
| `gnome-shell-extension-screenshot-window-sizer` | `screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com` | 按软件中心截图尺寸缩放窗口 |
| `gnome-shell-extension-shortcuts` | `Shortcuts@kyle.aims.ac.za` | 弹出快捷键帮助 |
| `gnome-shell-extension-status-icons` | `status-icons@gnome-shell-extensions.gcampax.github.com` | 部分状态图标放到顶栏 |
| `gnome-shell-extension-system-monitor` | `system-monitor@gnome-shell-extensions.gcampax.github.com` | 顶栏 CPU / 内存 / 网络 |
| `gnome-shell-extension-tiling-assistant` | `tiling-assistant@leleat-on-github` | 窗口吸附 / 平铺辅助 |
| `gnome-shell-extension-user-theme` | `user-theme@gnome-shell-extensions.gcampax.github.com` | 允许加载用户 Shell 主题（配合 Tweaks） |
| `gnome-shell-extension-weather` | `openweather-extension@penguin-teal.github.io` | 顶栏天气（Debian 13 是 OpenWeather 续作；旧 UUID `…@jenslody.de` 已失效） |
| `gnome-shell-extension-window-list` | `window-list@gnome-shell-extensions.gcampax.github.com` | 底栏窗口列表（偏经典桌面） |
| `gnome-shell-extension-windows-navigator` | `windowsNavigator@gnome-shell-extensions.gcampax.github.com` | 概览里用键盘选窗口 / 工作区 |
| `gnome-shell-extension-workspace-indicator` | `workspace-indicator@gnome-shell-extensions.gcampax.github.com` | 顶栏工作区指示与切换 |

未在本机装过的包，UUID 按 Debian / 上游常见值填写；若启用失败，看 `/usr/share/gnome-shell/extensions/` 实际目录名。

---

## 元包 / 工具（不是单个扩展）

| 软件包 | 作用 |
|---|---|
| `gnome-shell-extensions` | 官方扩展合集：会拉上 apps-menu、auto-move-windows、drive-menu、launch-new-instance、light-style、native-window-placement、places-menu、screenshot-window-sizer、system-monitor、user-theme、window-list、windows-navigator、workspace-indicator |
| `gnome-shell-extensions-common` | 官方扩展的公共文件（一般不用单独装） |
| `gnome-shell-extensions-extra` | 杂烩：disable-workspace-switcher、hibernate-status、just-perfection、middleclickclose、no-overview、vertical-workspaces |
| `gnome-shell-extension-prefs` | 官方「扩展」应用，开关扩展 |
| `gnome-shell-extension-manager` | 第三方扩展管理器（搜 / 开 / 关；也可装 extensions.gnome.org 的扩展） |

INDEX 1 / 2 默认只装上面那 7 个扩展包 + `gnome-shell-extension-prefs`，不装 `gnome-shell-extensions` / `extensions-extra`。其它扩展要装请写进 INDEX 3。

---

## 改完列表之后

1. 对应 apt 包要在 `4/cfg.sh` 的 INDEX 里（或手动 `apt install`）。
2. 把 UUID 写进 `Config.sh` 的 `SET_GNOME_EXTENSIONS_ENABLE`。
3. 需要改偏好时编辑 `7/cfg.sh` 里 `GNOME_EXT_*_DCONF`。
4. 已部署过的机器可只重跑检查点七，或手动：

```bash
gsettings set org.gnome.shell enabled-extensions "['dash-to-dock@micxgx.gmail.com', 'ubuntu-appindicators@ubuntu.com']"
gnome-extensions enable dash-to-dock@micxgx.gmail.com
```

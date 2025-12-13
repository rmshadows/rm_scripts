# Fluxbox配置

>https://fluxbox.org/

## 导入配置

将此文件夹移动到用户目录后重命名为`.fluxbox`

## 生成菜单

解压`OtherRes`中的`menumaker-0.99.14.tar.gz`，根据`README.md`文件安装`mmaker`

`./configure && sudo make install`

随后运行（运行前记得备份Menu）：`mmaker fluxbox`

可以将`backup`中的`menu.insert`内容合并到新生成的`menu`文件中

## 时间同步

`sudo apt install ntpdate`

`sudo ntpdate time.windows.com`

## 解决GTK应用没有标题栏的问题

将`OtherRes/gtk-display`文件夹中的`.gtkrc-2.0`放到用户目录下即可

## 通过`~/.fluxbox/apps`设置装饰条

### 使用Class

1️⃣ 获取窗口的匹配信息（非常关键）

打开那个 **没有标题栏的窗口**，然后运行：

```
xprop | grep -E "WM_CLASS|WM_NAME"
```

用鼠标点一下那个窗口，你会看到类似：

```

WM_CLASS(STRING) = "wechat", "WeChat"
WM_NAME(STRING) = "WeChat"
```

我们通常用 **WM_CLASS 的第二个值**。

2️⃣ 编辑 apps 文件

```
nano ~/.fluxbox/apps
```

加入一段（示例）：

```
[app] (class=WeChat)
  [Deco] {NORMAL}
  [Layer] {NORMAL}
  [Focus] {YES}
[end]
```

关键行解释

- `[Deco] {NORMAL}` 👉 **强制标题栏**
- `[Layer] {NORMAL}` 👉 防止被当成 dock
- `[Focus] {YES}` 👉 可聚焦

3️⃣ 重新加载 Fluxbox

```

fluxbox-remote reconfig
```

然后 **关闭并重新打开该程序窗口**。

### 如果 class 不匹配？用 name（备用）

有些程序 class 不稳定，可以用窗口名：

```
[app] (name=Settings)
  [Deco] {NORMAL}
[end]
```

⚠ name 会变，class 更稳。

## 其他

### **📂 目录**

**1. backgrounds** （📂 目录）

- 存放桌面壁纸文件。

**2. backup** （📂 目录）

- 存放 Fluxbox 相关的备份文件，可能是 `init`、`keys`、`menu` 等配置的旧版本。

**3. configs** （📂 目录）

- 存放 Fluxbox 的额外配置文件，可能包含主题、窗口规则、快捷键绑定等。

**4. OtherRes** （📂 目录）

- 可能存放额外的资源，比如主题、字体或其他辅助配置。

**5. pixmaps** （📂 目录）

- 存放图标或其他图片资源，一些 Fluxbox 主题可能会用到。

**6. scripts** （📂 目录）

- 存放用于 Fluxbox 的自定义脚本，比如窗口管理、亮度调节、音量控制等。

**7. setup** （📂 目录）

- 可能是自动化安装或配置 Fluxbox 的脚本集合。

**8. styles** （📂 目录）

- 存放 Fluxbox 主题样式文件（`.cfg` 或 `style` 结尾的文件）。

------

### **📄 文件**

**1. apps**（🚀 可执行文件，70字节）

- **疑点：**正常来说 `apps` 应该是 Fluxbox 的窗口规则文件，但这里是可执行文件，可能是自定义的可执行脚本。

```
! 配置 fbrun 应用的窗口行为
[app] (name=fbrun)
  ! 让 fbrun 居中显示
  [Position] (WINCENTER) {0 0}
  ! 设置窗口层级为普通窗口层级
  [Layer] {2}
  ! 设置窗口大小
  [Geometry] {600x200}
  ! 禁止窗口启动时最大化
  [Maximized] {false}
  ! 禁止窗口最小化
  [Minimized] {false}
  ! 允许窗口透明（需要合成管理器）
  [Alpha] {220}
  ! 移除窗口装饰（无边框）
  [Deco] {NONE}
  ! 让窗口始终保持在所有工作区
  [Sticky] {true}
  ! 窗口不会出现在任务栏
  [IconHidden] {true}
[end]

[Layer]
0 - Desktop      ! 桌面层（最底层，通常用于壁纸）
2 - Normal       ! 普通窗口（默认层级）
4 - AboveDock    ! 高于 Dock（例如任务栏或面板）
6 - Dock         ! Dock 层（类似任务栏）
8 - Top          ! 最高层，始终显示在最上方
10 - Menu        ! 菜单层（菜单弹出时使用）
12 - Above       ! 高于所有窗口（常用于浮动窗口或 HUD）
```

**2. apt-install.sh**（🚀 脚本，315字节）

- 可能是一个用于安装 Fluxbox 相关依赖的软件包安装脚本。

**3. fluxbox-init.tar.xz**（📦 归档文件，2376字节）

- 可能是 `~/.fluxbox/` 配置文件的备份压缩包，可用于快速恢复。

**4. init**（🚀 配置文件，3098字节）

- Fluxbox 的主配置文件，控制窗口管理行为。

**5. keys**（🚀 配置文件，5228字节）

- 存放快捷键绑定，比如：

  ```plaintext
  Mod4 t :ExecCommand x-terminal-emulator
  ```

- **Mod4** 代表 `Super`（Win 键）。

**6. lastwallpaper**（🚀 配置文件，154字节）

- 可能存储上次设置的壁纸路径，以便恢复或自动应用。

**7. menu**（🚀 配置文件，1746字节）

- 定义 Fluxbox 右键菜单内容，比如应用程序快捷方式等。

**8. overlay**（🚀 配置文件，123字节）

- 可能用于覆盖窗口管理规则（如窗口大小、边框、焦点行为）。

**9. README.md**（📄 文档，2852字节）

- 说明文件，解释如何使用此目录内的配置和脚本。

**10. slitlist**（🚀 配置文件，0字节）

- 用于管理 Slit（Fluxbox 的小部件容器）的窗口顺序，但目前为空。

**11. startup**（🚀 启动脚本，1053字节）

- 定义 Fluxbox 启动时运行的程序，例如：

  ```bash
  nm-applet &
  volumeicon &
  conky &
  exec fluxbox
  ```

**12. windowmenu**（🚀 配置文件，168字节）

- 定义窗口右键菜单内容，比如 "关闭"、"最小化" 等选项。

  ```
  shade - 最小化窗口，使窗口内容变为标题栏形式，便于节省空间。
  stick - 将窗口置为“粘性”窗口，即窗口会保持在工作区或屏幕上，无论工作区切换如何。
  maximize - 将窗口最大化。
  iconify - 将窗口最小化至任务栏（或者 Fluxbox 的 Slit 区域）。
  raise - 将窗口提升到其他窗口之上，成为前台窗口。
  lower - 将窗口降低至其他窗口之下，或送到后台。
  settitledialog - 设置窗口标题（通常用于修改标题）。
  sendto - 将窗口发送到指定的工作区。
  layer - 改变窗口层级（例如，置顶、底层等）。
  alpha - 调整窗口透明度。
  extramenus - 添加额外的菜单选项（如果配置了额外的自定义菜单）。
  separator - 菜单中的分隔线，用于分开不同类别的选项。
  close - 关闭当前窗口。
  ```

### **📌 总结**

包括： ✅ **窗口管理**（`init`、`apps`、`overlay`）
 ✅ **快捷键**（`keys`）
 ✅ **菜单**（`menu`、`windowmenu`）
 ✅ **主题**（`styles`）
 ✅ **脚本**（`scripts`、`startup`）
 ✅ **自动化安装**（`setup`、`apt-install.sh`）
 ✅ **备份**（`backup`、`fluxbox-init.tar.xz`）

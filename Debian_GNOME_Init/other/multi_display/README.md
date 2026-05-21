# 多屏幕 `xrandr` 命令参考

## 1️⃣ 设置主屏幕

```bash
# 语法：
xrandr --output <屏幕名称> --primary [--mode <分辨率>] [--pos XxY] --auto

# 示例：
xrandr --output HDMI-1 --primary --mode 1920x1080 --pos 0x0 --auto
```

说明：

- `--primary` ：指定主屏幕
- `--mode` ：指定分辨率（可选）
- `--pos XxY` ：屏幕左上角坐标（0x0 表示最左上角）

------

## 2️⃣ 打印屏幕信息

```bash
# 查看所有连接的显示器及状态
xrandr --query

# 仅列出屏幕名称
xrandr | awk '/ connected/ {print $1}'

# 查看详细模式和分辨率
xrandr | grep " connected" -A10
```

输出示例：

```
HDMI-1 connected primary 1920x1080+0+0 ...
DP-1 connected 1920x1080+1920+0 ...
eDP-1 connected 1920x1080+0+0 ...
```

------

## 3️⃣ 设置屏幕顺序（扩展桌面）

```bash
# 语法：
xrandr --output <屏幕A> --mode <分辨率A> --pos XxY --auto \
       --output <屏幕B> --mode <分辨率B> --right-of <屏幕A> --auto \
       --output <屏幕C> --mode <分辨率C> --left-of <屏幕B> --auto

# 简单示例：主屏左，拓展屏右
xrandr --output HDMI-1 --primary --mode 1920x1080 --pos 0x0 --auto \
       --output DP-1 --mode 1920x1080 --right-of HDMI-1 --auto
```

说明：

- `--right-of <屏幕>` ：设置在指定屏幕右侧
- `--left-of <屏幕>` ：设置在指定屏幕左侧
- `--above` / `--below` ：上下排列

------

## 4️⃣ 设置镜像（复制）屏幕

```bash
# 语法：
xrandr --output <屏幕B> --mode <分辨率> --same-as <屏幕A> --auto

# 示例：让 eDP-1 镜像 HDMI-1
xrandr --output eDP-1 --mode 1920x1080 --same-as HDMI-1 --auto
```

说明：

- `--same-as <屏幕>` ：复制指定屏幕内容
- 镜像屏幕分辨率必须与被复制屏幕相同

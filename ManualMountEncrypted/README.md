# ManualMountEncrypted

手动挂载加密卷：`BitLocker/`（dislocker）与 `VeraCrypt/`。

先改对应目录下的 `config.sh`，再跑入口脚本。

## 目录

| 目录 | 入口 | 说明 |
|------|------|------|
| `BitLocker/` | `mountB.sh` / `rmount.sh` / `urmount.sh` | BitLocker 分区 |
| `VeraCrypt/` | `mountV.sh` / `rmount.sh` / `urmount.sh` | VeraCrypt 分区或容器文件 |

Debian 官方源通常**没有** `veracrypt`，有 `tcplay`。脚本优先用已安装的 `veracrypt`；找不到且源里也没有时，会询问是否改用 `tcplay`（PIM 须为 0；隐藏卷 / 系统加密可能打不开）。

挂载点默认在 `/media/$USER/…`，方便 Nautilus 侧栏出现。`mountNameMode` 可按卷标命名。

## 打包成单文件（shc）

两边都有 `pack_shc.sh`：把脚本 + **当时的** `config.sh` 合成一份，核对后再用 **shc** 编成二进制。

### `build-shc/` 是什么

**打包输出目录**（可随时删，再跑 `./pack_shc.sh` 会重建），不是运行时依赖目录。

| 文件 | 作用 |
|------|------|
| `mountV-packed.sh` / `mountB-packed.sh` | 合并后的纯 shell，给人核对（也可用 `bash` 直接跑） |
| `mountV` / `mountB` | shc 编出的可执行文件；拷到别的机器主要带这个 |

打包**不会**把 `veracrypt` / `dislocker` 打进去。目标机仍需已安装对应工具。

```bash
cd BitLocker   # 或 VeraCrypt
./pack_shc.sh              # 生成 → 展示 config → 确认 → shc
./pack_shc.sh --no-shc     # 只生成合并脚本，不调用 shc
./pack_shc.sh --yes        # 不询问，直接 shc
```

```bash
# 与 mountV.sh / mountB.sh 一样：无参数 = 交互询问挂/卸
./build-shc/mountV
./build-shc/mountB

# 可选快捷（非必须）
./build-shc/mountV --mount
./build-shc/mountV --umount
```

### 打包后「用不了」常见原因

1. **没在终端运行**（双击/文件管理器打开）→ 看不到密码提示 / sudo 询问，像没反应。
2. **目标机没有** `veracrypt`（VeraCrypt）或 `dislocker`（BitLocker）。
3. **`config.sh` 改过但没重新** `./pack_shc.sh` → 二进制里仍是旧快照。
4. **`keyPass` 留空**时必须在真实终端输入密码；管道/无 TTY 环境会解密失败。
5. 卷标目录已占用时会自动变成 `卷标_2`、`卷标_3`，不是挂失败。

> `keyPass` **不要**写进 `config.sh` 再打包：密码会进 `*-packed.sh`（明文）。交互输入更安全。

### 安装 shc

**Debian / Ubuntu 官方源通常没有 `shc` 包**（`apt install shc` 会报「无法定位软件包」）。从源码安装：

```bash
sudo apt install build-essential autoconf automake
git clone --depth 1 https://github.com/neurobin/shc.git /tmp/shc
cd /tmp/shc
./autogen.sh         # 按本机 automake 重新生成（勿直接 make）
./configure
make
sudo make install    # → /usr/local/bin/shc
hash -r              # 若 zsh 仍提示找不到，刷新命令缓存
shc -h | head -1     # 应看到 Version 4.0.x
```

暂时不装 shc 时用 `./pack_shc.sh --no-shc`，用 `bash build-shc/*-packed.sh` 即可。

> shc 只是提高拷走的便利性，**不是**对密码的可靠保护。

## 桌面快捷键（弹窗 → 交互跑 → 跑完关窗）

`run-in-terminal.sh` 是**通用**小工具：只负责「找/指定一个终端 → 跑你给的命令 → 跑完关窗」，不绑定 VeraCrypt/BitLocker，也不需要被 shc 打包。拷走 `mountV`/`mountB` 后，快捷键里写上它们的路径即可。

```bash
chmod 775 ManualMountEncrypted/run-in-terminal.sh

# 自动选终端
./run-in-terminal.sh /绝对路径/VeraCrypt/build-shc/mountV

# 显式指定终端 / 跑完停住（快捷键里直接写这些参数即可）
./run-in-terminal.sh -t xterm /绝对路径/build-shc/mountV
./run-in-terminal.sh --term gnome-terminal --hold /绝对路径/build-shc/mountV
./run-in-terminal.sh -t xterm -H /绝对路径/BitLocker/build-shc/mountB
```

没有本脚本时，也可以直接把快捷键设成（效果类似）：

```bash
x-terminal-emulator -e /绝对路径/build-shc/mountV
# 或
xterm -e /绝对路径/build-shc/mountV
```

### GNOME

设置 → 键盘 → 查看并自定义快捷键 → 自定义快捷键 → `+`：

| 项 | 示例 |
|----|------|
| 名称 | VeraCrypt 挂载 |
| 命令 | `/path/to/run-in-terminal.sh -t gnome-terminal /path/to/VeraCrypt/build-shc/mountV` |
| 快捷键 | 自定，如 `Super+Shift+V` |

### Fluxbox

`~/.fluxbox/keys`：

```
Mod4 Shift v :Exec /path/to/run-in-terminal.sh -t xterm /path/to/VeraCrypt/build-shc/mountV
Mod4 Shift b :Exec /path/to/run-in-terminal.sh -t xterm -H /path/to/BitLocker/build-shc/mountB
```

没终端就：`sudo apt install xterm`。

### 其它桌面

快捷键命令栏同样填：`run-in-terminal.sh` + 选项 + **你的**可执行文件绝对路径即可。仍可用环境变量 `TERM_CMD` / `HOLD=1`，与 `-t` / `-H` 等价。

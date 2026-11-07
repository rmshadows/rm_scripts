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

## 一次性码

同事电脑上不要敲卷口令。卷头认的口令不变。一次性码只用来解开你 U 盘上的一个槽，槽里是加密后的卷口令。挂载成功后，脚本删掉这个槽，纸上那条码就不能再推出卷口令。

键盘记录器记到的是这条码。它自己打不开卷。槽文件如果在你插入 U 盘之前就被整盘拷走，再配上这条码，仍然可以解出卷口令。所以槽放在自己带着的 U 盘里，用的时候才插上。

不用 TOTP。验证器的 6 位数要靠一把长期密钥加当前时间算出来。时间是公开的；密钥若放在解密那台电脑上，对方不必看键盘就能自己算。6 位数只有一百万种，也不能拿来加密槽文件。

在自己电脑上生成（会问两次卷口令，只打印码，不把码写进文件）：

```bash
chmod +x ManualMountEncrypted/otp/enroll.sh
cd /你想先放下的目录
./ManualMountEncrypted/otp/enroll.sh
```

不写目录就生成在当前文件夹，之后把 `slot-*` 或 `key-*` 剪到 U 盘。写了路径就直接生成到那个目录。

`config.sh` 里 `otpMode` 默认是 `1`：卷口令和一次性码都能用。`keyPass` 写了内容就直接用这口令，不再询问。`keyPass` 留空时，提示里可以输入纸上的一条码，也可以直接输入卷口令。像一次性码但找不到对应槽时，不会把它当成卷口令。`otpMode=0` 则只走原来的卷口令。`otpSlotDir` 留空就在确认是一次性码之后再问槽目录。

一次生成多条，默认 10 条。每一条只能成功用一次，用掉的是那一个文件，其余还在。

长码仍是默认。要好输入的数字，用 `--pin`（默认 8 位，可写到 20 位）。PIN 和长码一样只打印一次，不写进文件。8 到 20 位纯数字会先当作 PIN。

不想敲，用 `--keyfile`。每个 `key-` 文件自己带了解开材料，放进 `otpSlotDir` 那个目录就会用掉一个并删除，不用输入。这种文件被拷走就能解开，直到你用过并删掉它。

```bash
./ManualMountEncrypted/otp/enroll.sh --pin 8
./ManualMountEncrypted/otp/enroll.sh --pin 16
./ManualMountEncrypted/otp/enroll.sh --keyfile
```

需要本机有 `python3` 和 `openssl`。重新 `./pack_shc.sh` 之后，打包结果里会带上解开槽的程序，不会带上槽文件和码。

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

快捷键命令栏同样填：`run-in-terminal.sh` + 选项 + **你的**可执行文件绝对路径即可。默认跑完停住，按任意键关窗。`HOLD=0` 则跑完即关。环境变量 `TERM_CMD` / `HOLD=1` 与 `-t` / `-H` 等价。

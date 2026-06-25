# KVM Manager

用 Bash + `virsh` 管理 KVM/libvirt 虚拟机，**不依赖 virt-manager GUI**。  
推荐 **菜单式交互**，只需记一个入口命令。

路径：`Other/KVM_Manager/`

---

## 依赖

```bash
sudo apt install libvirt-clients qemu-utils virt-viewer
sudo systemctl enable --now libvirtd

# 可选：少输 sudo（改完后需重新登录）
sudo usermod -aG libvirt "$USER"
```

| 组件 | 用途 |
|------|------|
| `libvirt-clients` | `virsh` 管理 VM / 网络 / 存储池 |
| `qemu-utils` | `qemu-img` 创建 qcow2、查看占用 |
| `virt-viewer` | Spice 图形界面、**宿主机↔Guest 剪贴板** |

`3-kvm_vm.sh start` 启动 VM 时会**自动尝试拉起**其依赖的虚拟网络（如 `default`）。

---

## 快速开始

```bash
cd Other/KVM_Manager
chmod +x kvm.sh [0-9]-kvm_*.sh

sudo ./kvm.sh          # 推荐：总菜单
# 或单独进子菜单
sudo ./0-kvm_info.sh
sudo ./3-kvm_vm.sh
```

### 权限说明（重要）

本地配置默认连接 **`qemu:///system`**（系统级 VM，XML 在 `/etc/libvirt/qemu/`）。

| 操作 | 是否需要 sudo |
|------|----------------|
| 查看列表 / 详情 / 状态 | 可读时不必；无权限时用 sudo |
| 启动 / 关机 / 快照 / 共享 / 新建 VM / 改 XML | **需要 sudo 或 libvirt 组** |

总菜单顶部会提示：`写入操作请用 sudo ./kvm.sh`。

### 菜单交互

- **无参数**运行任一脚本 → 进入数字子菜单
- 子菜单 **空回车** 或 **q** → 返回上级（总菜单或退出）
- 操作完成后 **Enter** → 继续当前子菜单；**q** → 返回上级
- 命令行参数仍保留（如 `3-kvm_vm.sh start debian11`），便于脚本自动化

---

## 总菜单 `kvm.sh`

| 选项 | 脚本 | 功能 |
|------|------|------|
| 1 | `0-kvm_info.sh` | 查看 VM 列表 / 详情 / 快照概要 |
| 2 | `3-kvm_vm.sh` | 电源、virt-viewer 界面、自启动 |
| 3 | `1-kvm_net.sh` | 虚拟网、NAT/桥接、default 启停 |
| 4 | `2-kvm_disk.sh` | 单独建 qcow2、看占用、挂盘 |
| 5 | `4-kvm_share.sh` | 9p 共享目录、Guest 挂载说明、Spice 剪贴板 |
| 6 | `5-kvm_snapshot.sh` | 快照列表 / 创建 / 恢复 / 删除 |
| 7 | `6-kvm_create.sh` | 交互式新建完整 VM |
| 8 | — | 重新配置 libvirt 连接 URI |
| q | — | 退出 |

---

## 文件一览

| 文件 | 说明 |
|------|------|
| `kvm.sh` | **总菜单入口（推荐）** |
| `kvm_lib.sh` | 公共库（virsh 封装、中文兼容、菜单 helper） |
| `0-kvm_info.sh` | 信息查看 |
| `1-kvm_net.sh` | 网络管理 |
| `2-kvm_disk.sh` | qcow2 磁盘 |
| `3-kvm_vm.sh` | 电源与控制台 |
| `4-kvm_share.sh` | 共享文件夹 (9p) |
| `5-kvm_snapshot.sh` | 快照 |
| `6-kvm_create.sh` | 新建 VM |
| `kvm.local.conf` | 本地 URI 配置（gitignore，首次运行生成） |
| `kvm.conf.example` | 配置示例 |
| `kvm_completion.bash` | Bash Tab 补全（可选） |
| `kvm_snapshot.sh` | 兼容入口，转发到 `5-kvm_snapshot.sh` |

---

## 本地配置

首次运行会写入 **`kvm.local.conf`**（`KVM_VIRSH_URI`）。也可：

```bash
sudo ./0-kvm_info.sh --setup
# 或总菜单 → 8) 配置连接
```

示例见 `kvm.conf.example`。常见值：

- `qemu:///system` — 系统级 VM（多数桌面安装默认）
- `qemu:///session` — 当前用户会话 VM

---

## 各模块说明

### 0 — 查看 `0-kvm_info.sh`

- 列出全部 VM（状态、CPU、内存、**定义 XML 路径**、**磁盘路径**）
- 单台详情：磁盘、网卡、位置
- 命令行：`./0-kvm_info.sh -d <名称> [-s]`（含快照列表）

### 1 — 网络 `1-kvm_net.sh`

- **NAT**：`type=network`，接 libvirt 的 `default` 等虚拟网
- **桥接**：`type=bridge`，接到宿主机 `br0` 等
- 切换 NAT/桥接 **要求 VM 已关机**，会保留 MAC
- 菜单含：列出虚拟网 / 网桥、查看 VM 网卡、**启动/停止 default**、**开机自启**

```bash
sudo ./1-kvm_net.sh list
sudo ./1-kvm_net.sh switch debian11    # 需先关机
sudo ./1-kvm_net.sh start default
```

### 2 — 磁盘 `2-kvm_disk.sh`

只创建 qcow2 文件，不注册 VM。适合数据盘或先建盘再挂。

| 命令 | 说明 |
|------|------|
| `create` | 向导选存储池；或 `create -p KVM_W 名 64` |
| `info` | virtual size vs 宿主机实际占用 |
| `attach` | 关机状态下挂到已有 VM |
| `pool list` | 存储池与容量 |

### 3 — 电源 `3-kvm_vm.sh`

| 命令 | 说明 |
|------|------|
| `start [--view]` | 启动；`--view` 用 virt-viewer 开界面 |
| `console` / `view` | 打开 Spice 界面 |
| `shutdown [--force]` | 优雅关机；无系统盘时可 `--force` |
| `reboot` / `destroy` | 重启 / 强制断电 |
| `status` | 状态与自启动 |
| `autostart on\|off` | 宿主机重启后是否自动启动 VM |

### 4 — 共享 `4-kvm_share.sh`

管理 libvirt XML 里的 `<filesystem type='mount'>`（**9p**）。  
脚本只改宿主机配置；**Guest 内还需 mount** 才能看到文件。

| 命令 | 说明 |
|------|------|
| `list [VM]` | 列出共享；附一行 Linux 挂载示例 |
| `add [VM] <宿主机路径> <Guest标签>` | 添加（需 VM 已关机） |
| `remove [VM] <标签>` | 移除 |
| `guide [VM]` | **完整 Guest 命令**（mount、fstab、剪贴板） |
| `spice [VM]` | 补 Spice 剪贴板 XML 通道（需 VM 已关机） |

**Linux Guest 挂载示例**（标签 `Share` 须与 add 时一致）：

```bash
sudo modprobe 9pnet_virtio
sudo mkdir -p /mnt/Share
sudo mount -t 9p -o trans=virtio,version=9p2000.L,rw Share /mnt/Share
```

**剪贴板**：宿主机用 **virt-viewer** 连接；Guest 内 `sudo apt install spice-vdagent && sudo systemctl enable --now spice-vdagent`。  
新建 VM（`6-kvm_create.sh`）默认已带 Spice 通道；旧 VM 可用 `4-kvm_share.sh spice <VM>`。

### 5 — 快照 `5-kvm_snapshot.sh`

| 命令 | 说明 |
|------|------|
| `list [VM]` | 名称、时间、**当前位置**、上级、**描述**、树形层级 |
| `create [VM] [名] [--desc "说明"]` | 创建；运行中需 `--live` |
| `revert [VM] [快照]` | 恢复（**建议先关机**） |
| `delete [VM] [快照]` | 删除（需确认） |
| `info [VM] [快照]` | 详情 |

- **qcow2** 磁盘支持最好
- 创建时建议加 `--desc`，否则列表显示「（无）」
- 已有快照无法事后补描述，只能新建时填写

```bash
sudo ./5-kvm_snapshot.sh create debian11 before-upgrade --desc "升级前"
```

### 6 — 新建 VM `6-kvm_create.sh`

向导步骤：**名称 → 安装方式 → 存储池 → 大小/内存/CPU → 确认**

| 创建方式 | 说明 |
|----------|------|
| 1) ISO | 挂光盘 + 空硬盘 |
| 2) 空盘 | 稍后自行挂 ISO |
| 3) 导入 qcow2 | cloud 镜像等 |

- 磁盘路径固定为：**`{存储池目录}/{VM名}.qcow2`**（不会自动复用其它文件名）
- 名称已占用会提示已有 XML/磁盘路径，要求换名
- 创建失败时可能留下 orphan `.qcow2`，列表里没有 VM → 用新名重试或手动清理

**存储池**（以本机 `virsh pool-list` 为准）：

| 池名 | 典型路径 | 说明 |
|------|----------|------|
| KVM | `~/KVM` | home 分区 |
| KVM_W | 外置挂载点 | 空间充裕时优先 |
| n) 新建 | 自定义目录 | 可注册移动硬盘目录为新池 |

创建后：`sudo ./kvm.sh` → 2) 电源 → 1) 启动并打开界面。

---

## 可选：Tab 补全

```bash
source /path/to/Other/KVM_Manager/kvm_completion.bash
```

对 `3-kvm_vm.sh`、`5-kvm_snapshot.sh` 等命令行模式补全 VM 名、子命令。

---

## 设计说明

- 只读操作尽量安全；写操作（destroy、switch、share、快照恢复/删除）有确认或关机检查
- 配置写入 libvirt / 本地 `kvm.local.conf`，不修改 Nginx 等其它服务
- 兼容**中文 virsh** 输出（状态「运行/关闭」、存储池「活动/运行」等）

---

## 常见问题

**Q: 新建 VM 后列表里没有？**  
A: 多半未用 `sudo`，`virsh define` 失败但可能已建 qcow2。请 `sudo ./kvm.sh` 重试，或 `0-kvm_info.sh` 确认连接 URI。

**Q: 共享 add 了但 Guest 里看不到？**  
A: 9p 需在 Guest 内 `mount`；运行 `sudo ./4-kvm_share.sh guide <VM>` 看完整命令。

**Q: 剪贴板不工作？**  
A: 需 virt-viewer + Guest 内 spice-vdagent + XML 有 spicevmc 通道（`4-kvm_share.sh spice <VM>`）。

**Q: 存储池显示未启动但 pool-start 报已活动？**  
A: 已修复中文状态识别；更新到当前脚本即可。

**Q: 快照列表没有描述？**  
A: 创建时需 `--desc "说明"`；旧快照无描述则显示「（无）」。

---

## 尚未包含（有意不做或以后再加）

- VM **删除 / 克隆 / 迁移**
- `virt-install` 全自动装系统（当前为 define + 空盘/ISO）
- Guest 内自动 mount（超出 virsh 范围，见 `guide` 手动步骤）

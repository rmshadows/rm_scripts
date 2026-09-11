# rm_scripts
我自己写的一些脚本以及网上收集的、网友贡献的脚本。注意看README文件，有一部分脚本已经不再维护！

这里主要是系统搭建脚本，其他脚本见杂货铺:

[Github](https://github.com/rmshadows/whatarethese)  |  [Gitee](https://gitee.com/rmshadows/shenmedongxi) (几乎停更)

## 一键拉取（无需 git）

两种来源：

- **Release 附件**（精简包，推荐日常部署）：不含 `archive/`、日志和凭据文件。一键 URL 用固定 tag **`debian-init`**，不是 `/releases/latest/`（仓库里的 latest 可能是你手动发的 PDF 工具）。发版：仓库 **Actions → Publish Init Release → Run workflow**（选要打包的分支；会同时打一个版本快照 tag，并覆盖 `debian-init`）。本地也可：`bash release/build.sh && bash release/publish.sh v0.1.6`。
- **GitHub 分支压缩包**（`main` / `dev`，不用等发版）：拿最新代码。下载的是**整个仓库**，体积更大，且含 `archive/`。需要 GNU tar（Debian 自带）。

**拉取后跑部署仍然可以**，但不再是完全无人值守：必须在**真实终端**里运行入口脚本，**首次输入 `y`**（直接回车 = 取消）。管道/`curl | bash`、没分配 TTY 的 SSH 会直接退出。GNOME 会先警告并检查；Server 不会再用默认 `admin`/`passwd`（太弱），确认后会问自动生成或自己输入，或用环境变量传入**足够强**的 `SET_USER_NAME` / `SET_USER_PASSWD`。

### 1. 仅拉取 Release（不解压后不运行）

**Debian GNOME Init**

```bash
curl -fsSL -o Debian_GNOME_Init.tar.gz \
  https://github.com/rmshadows/rm_scripts/releases/download/debian-init/Debian_GNOME_Init.tar.gz
tar -xzf Debian_GNOME_Init.tar.gz
# 得到目录 Debian_GNOME_Init/ ，自行改 Config.sh / GlobalVariables.sh 后再运行
```

**Debian Server Init**

```bash
curl -fsSL -o Debian_Server_Init.tar.gz \
  https://github.com/rmshadows/rm_scripts/releases/download/debian-init/Debian_Server_Init.tar.gz
tar -xzf Debian_Server_Init.tar.gz
# 得到目录 Debian_Server_Init/ ，自行改 Config.sh 后再运行
```

可选校验：

```bash
curl -fsSL -O https://github.com/rmshadows/rm_scripts/releases/download/debian-init/SHA256SUMS
sha256sum -c SHA256SUMS
```

钉死某一版时把 `debian-init` 换成快照 tag（例如 `v0.1.6` / `v2026.09.11`）。

### 2. 从 GitHub 分支拉取（main / dev）

下面命令把对应目录**直接解到当前文件夹**。把 `dev` 换成 `main` 即主分支；目录前缀跟着改成 `rm_scripts-main/`。

**只要 GNOME Init**

```bash
curl -fsSL https://github.com/rmshadows/rm_scripts/archive/refs/heads/dev.tar.gz \
  | tar -xz --strip-components=1 rm_scripts-dev/Debian_GNOME_Init
```

**只要 Server Init**

```bash
curl -fsSL https://github.com/rmshadows/rm_scripts/archive/refs/heads/dev.tar.gz \
  | tar -xz --strip-components=1 rm_scripts-dev/Debian_Server_Init
```

**整个仓库解到当前目录**（会把仓库根文件混进当前文件夹，建议先建空目录再执行）：

```bash
mkdir -p rm_scripts && cd rm_scripts
curl -fsSL https://github.com/rmshadows/rm_scripts/archive/refs/heads/dev.tar.gz \
  | tar -xz --strip-components=1
```

### 3. 拉取 + 运行（命令行传入必要参数）

先按上面任一方式拉到目录，再在**终端**里跑。参数通过**环境变量**覆盖配置（勿把密码写进可分享的截图/日志）。

**GNOME**（普通用户跑；若还不是免密 sudo，请提供 `ROOT_PASSWD`）

```bash
curl -fsSL \
  https://github.com/rmshadows/rm_scripts/releases/download/debian-init/Debian_GNOME_Init.tar.gz \
  | tar -xz
cd Debian_GNOME_Init
ROOT_PASSWD='你的root密码' bash Debian_13_GNOME_Setup.sh
# 首次输入 y 开始；已是免密 sudo 时可省略 ROOT_PASSWD
```

**Server**（建议 **root** 跑；首次输入 `y`。不要再用 `admin`/`passwd`）

```bash
curl -fsSL \
  https://github.com/rmshadows/rm_scripts/releases/download/debian-init/Debian_Server_Init.tar.gz \
  | tar -xz
cd Debian_Server_Init
bash Debian_13_Server_Setup.sh
# 输入 y 后选：1 自动生成账号（回车默认）或 2 自己输入；生成的密码只显示一次，请立刻抄下
# 或事先指定强账号：
# SET_USER_NAME='mysvc' SET_USER_PASSWD='足够长的密码' bash Debian_13_Server_Setup.sh
# 可选：SET_HOST_NAME='myserver'
# SET_USER=0 则以 root 继续，不建普通用户
```

更稳妥做法：先「仅拉取」，打开 `Config.sh` 确认后再跑入口脚本。Server 也可先 `bash gen_credentials.sh` 再部署。

## 脚本文件夹

- **systweak**——已有系统上的单功能开关（拷哪个用哪个，支持 `--undo`）。详见 [`systweak/README.md`](systweak/README.md)
- Debian_GNOME_Init——用于部署新的Debian系统
  - *Debian10_GNOME.sh——Debian 10(Buster) GNOME配置脚本(停止更新，最终版本v3.3.7)*
  - Debian11_GNOME.sh——Debian 11(Bullseye) GNOME配置脚本
- Debian_Server_Init——用于初始化新的服务器
  - *Debian10_Server_Init.sh——Debian 10服务器部署(停止更新，最终版本v0.0.4)*
  - Debian11_Server_Init.sh——Debian 11服务器部署(停止更新)
  - Debian12_Server_Init.sh——Debian 12服务器部署
  - rsshub_docker.sh——简单粗暴删除RSSHUB后重装启动
- *forKylinV10SP1*——旧版系统微调（归档，请改用 systweak）
- FFmpeg——命令行调用FFmpeg工具处理视频
  - 详情见文件夹README
- fmgr文件传输——Nginx+Php fpm的文件共享（可上传），用于Linux主机临时局域网共享文件（直接丢进nginx根目录）
- JavaReleaseJpackage——用来的包Java程序
- Office——Office相关的脚本
- RAR——RAR相关脚本
  - 详情见文件夹README
- Windows——一些Windows的脚本(基本都是没用的东西)
  - OpenApplicationDownloadPages.bat——打开软件下载页面

## 未分类脚本

- *Docker-WeChat.sh——[Docker微信](https://github.com/huan/docker-wechat)(最后更新时间：2021.8)*

## 大事件记录

>各脚本更新日志请分别查看文件夹中的README

- 2026年9月11日——0.1.2
  - 新增 GitHub Action「Publish Init Release」（手动触发）：打包 Init 并覆盖固定 tag `debian-init`（一键 curl 用这个，不走 `/releases/latest/`，避免和 PDF 手动 Release 抢 latest）
  - 主 README：补充从 `main`/`dev` 分支 curl 解压；说明首次部署须终端输入 `y`，Server 不再接受默认 `admin`/`passwd`
  - Debian_GNOME_Init 0.1.2：部署前警告与检查，首次必须 `y` 确认；修复 Docker 清除开关逻辑反了
  - Debian_Server_Init 0.1.7：无现成账号时询问自动生成或自己输入（不再默认 admin/passwd）；修复 Docker 清除开关逻辑反了
  - 直播 ffmpegL：`livectl` 切歌/跳转；内存上限改为安装时可选
  - systweak：`wechat-recv-writable.sh`（微信接收文件目录可写）

- 2026年8月29日——0.1.1
  - Debian_GNOME_Init：续跑、TTY 交互、精简白霜离线包入库、fcitx5 登录自启

- 2026年7月31日——0.1.0
  - 新增 systweak（单脚本系统微调，可 --undo）；forKylinV10SP1 标为归档
  - 主 README 增加 Release 一键拉取说明；Server Init 可选 acme.sh

- 2026年4月27日——0.0.9
  - Office更新了PDF模块
  
- 2026年1月31日——0.0.8
  - Debian_Server_Init 应用安装：docker_rsshub、isso 增加 Nginx 反代片段与 setupNginx 脚本，安装后自动写入 `/etc/nginx/snippets/`，用户只需在 site 内加一行 include
  - application_install-sample 作为应用安装模板：新增 myapp-snippet.conf、setupNginxForMyapp.sh、README.md，主脚本与 Nginx 片段流程与现有应用（artalk、frp、rsshub、isso 等）一致

- 2026年1月11日——0.0.7
  - 更新了Office套件

- 2025年10月4日
  - 迁移完毕（但未测试）

- 2025年9月30日——0.0.6
  - 0.0.6 准备从Debian12升级Debian13

- 2025年2月12日
  - 重构了Debian_GNOME_Init和Debian_Server_Init

- 2024年7月6日
  - 更新了Office模块

- 2024年4月17日
  - 添加了Office模块

- 2024年2月22日
  - 更新脚本：Debian 11 -> Debian 12

- 2023年10月10日
  - 新增`fmgr`文件共享

- 2023年9月13日
  - `Debian 12`中raspi-firmware可能导致系统升级失败，建议`sudo apt purge raspi-firmware`

- 2022年9月23日
  - 添加了FFmpeg、RAR辅助工具
- 2022年3月29日
  - 添加了一个简单粗暴的Docker RSSHub安装脚本(不建议直接运行，更建议作为备忘录看一看就好)
- 2022年3月11日
  - 更新了Debian 11 GNOME部署脚本0.0.7
- 2021年10月27日
  - 发布修复了BUG的Debian 11 GNOME部署脚本正式版0.0.5
  - 发布Debian 11桌面部署脚本正式版0.0.4
- 2021年9月28日
  - **停止对Debian 10 脚本的更新**
  - 开始Debian 11脚本的编写，采用**预配置的方式一键部署**

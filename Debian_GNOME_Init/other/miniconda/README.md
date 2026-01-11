# Miniconda

## 安装和卸载

```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash ~/Miniconda3-latest-Linux-x86_64.sh

# 无人值守：
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm ~/miniconda3/miniconda.sh
source ~/miniconda3/bin/activate
conda init --all

# 手动初始化Manual shell initialization
source <PATH_TO_CONDA>/bin/activate
conda init --all
conda init --all --dry-run

# 卸载
conda deactivate
~/miniconda3/uninstall.sh
或者(看你安装在哪)
sudo -E /opt/miniconda3/uninstall.sh

备份：conda env export --name <ENV_NAME> > <ENV_NAME>.yaml

(Optional) If you have created any environments outside your miniconda3 directory, Anaconda recommends manually deleting them to increase available disc space on your computer. This step must be performed before uninstalling Miniconda.
conda info --envs
~/miniconda3/_conda constructor uninstall --prefix <PATH_TO_ENV_DIRECTORY>
```

## 配置

```
# 更换国内源
# 1. 备份旧配置
[ -f ~/.condarc ] && cp ~/.condarc ~/.condarc.bak
conda config --show default_channels                                    2 ⨯
default_channels:
  - https://repo.anaconda.com/pkgs/main
  - https://repo.anaconda.com/pkgs/r

# 只用 defaults
# conda config --add channels defaults
conda config --set channel_priority strict
conda config --set show_channel_urls yes

# 配置
# 建议直接修改~/.condarc
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud

# 验证
conda config --show channels
# 清索引缓存
conda clean -i
==========================
# 新建只用 conda-forge 的环境（不改全局）
conda create -n cf-env python=3.13 -c conda-forge --strict-channel-priority

# 临时指定：
conda activate cf-env
conda install --override-channels -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge numpy

conda config --show channels
conda config --show default_channels


# 安装Mamba
conda install -n base -c conda-forge mamba

mamba create -n myenv python=3.10
mamba install numpy pandas
mamba update --all

# 不自动进入base
conda config --set auto_activate false

# 新建并设置自动进入default虚拟环境
mamba create -n dev python=3.13
在shell rc文件最后一行新增
conda activate dev

##############DISCARD
# 先清理可能已有的乱七八糟配置（可选但推荐）
# conda config --remove-key channels
# conda config --remove-key default_channels

# defaults 指向清华镜像（不建议）
conda config --set default_channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
conda config --append default_channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
# conda config --append default_channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
# conda config --set custom_channels.conda-forge https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
```

### Windows

```
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
conda config --set show_channel_urls yes
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge
conda config --set channel_priority strict

或者：
C:\Users\你的用户名\.condarc

channels:
  - defaults
show_channel_urls: true
channel_priority: strict

default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2

custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple


. : 无法加载文件 C:\Users\Manjaro\Documents\WindowsPowerShell\profile.ps1，因为在此系统上禁止运行脚本。有关详细信息，请
参阅 https:/go.microsoft.com/fwlink/?LinkID=135170 中的 about_Execution_Policies。
所在位置 行:1 字符: 3
+ . 'C:\Users\Manjaro\Documents\WindowsPowerShell\profile.ps1'
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) []，PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
PS C:\Users\Manjaro\Desktop\PDF_Tools> conda
conda : 无法将“conda”项识别为 cmdlet、函数、脚本文件或可运行程序的名称。请检查名称的拼写，如果包括路径，请确保路径正
确，然后再试一次。
所在位置 行:1 字符: 1
+ conda
+ ~~~~~
    + CategoryInfo          : ObjectNotFound: (conda:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException

解决：Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

## 使用

```
一、查看环境
conda env list
# 或
conda info --envs

二、新建环境
1️⃣ 新建（最常用）
conda create -n dev python=3.13

2️⃣ 用 mamba（更快，推荐）
mamba create -n dev python=3.13

3️⃣ 指定包一起装
mamba create -n dev python=3.13 numpy requests ipython

4️⃣ 指定 channel（一次性，不改全局）
mamba create -n dev python=3.13 \
  --override-channels \
  -c https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main \
  --strict-channel-priority

三、激活 / 退出环境
conda activate dev
conda deactivate

四、删除环境（最重要）
⚠️ 删除前先退出
conda deactivate

删除整个环境
conda remove -n dev --all

（mamba 也可以）

mamba remove -n dev --all

五、重建“默认 debug 环境”（你现在的需求）
conda deactivate
conda remove -n dev --all
mamba create -n dev python=3.13

六、复制一个环境（可选）
conda create -n dev-copy --clone dev

七、导出 / 复现环境（可选但常用）
导出
conda env export -n dev > dev.yml

复现
conda env create -f dev.yml

八、环境内装包 / 卸包
mamba install numpy pandas
mamba remove numpy

九、清理缓存（环境炸了常用）
conda clean -a -y
mamba clean -a -y

关掉 conda 自动前缀 (dev)
conda config --set changeps1 false
```


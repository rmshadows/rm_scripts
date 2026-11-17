# Office

说明：处理Office文件。

作者：Ryan Yim

Github：https://github.com/rmshadows/

## 目录

* **0-Off-init.sh**：依赖安装并复制到文件管理器右键。两种虚拟环境模式，改脚本顶部 `VENV_MODE`，或用命令行：
  * **1 / auto**（默认）：自动检测，有就用。看当前终端（`VIRTUAL_ENV` 或 conda 的 `CONDA_PREFIX`），再看 `~/.config/office/python-venv`、`~/.python_venv_activate`、`~/.PythonVenv`，都没有才新建。`./0-Off-init.sh --venv-auto`
  * **2 / fixed**：固定目录，没有就新建，有就沿用。目录写在 `FIXED_VENV_DIR`，留空就是 `~/.PythonVenv`。不看当前终端。`./0-Off-init.sh --venv-fixed` 或 `./0-Off-init.sh --venv-fixed ~/myenv`
  * 模式 1 里还可以写 `MANUAL_VENV_DIR`，或临时 `PYTHON_VENV_DIR=/路径 ./0-Off-init.sh`。激活命令写入 bashrc 和 zshrc。右键不读这两个文件，读配置文件。装完会打印每一项以后改哪里。`./0-Off-init.sh --status` 只看检测结果和修改位置。

### 安装以后改哪里

| 要改的 | 去哪改 |
| --- | --- |
| 虚拟环境模式 | 脚本顶部 `VENV_MODE`：`auto`/`1` 自动检测有就用，`fixed`/`2` 固定目录。或 `--venv-auto`、`--venv-fixed [目录]` |
| 模式 2 的目录 | 脚本顶部 `FIXED_VENV_DIR`，留空是 `~/.PythonVenv`。没有就新建，有就沿用 |
| 模式 1 里锁定目录 | `0-Off-init.sh` 顶部 `MANUAL_VENV_DIR`，改完重新运行 |
| 只换以后终端和右键用的目录 | `~/.config/office/python-venv`，一行绝对路径 |
| 临时指定一次 | `PYTHON_VENV_DIR=/路径 ./0-Off-init.sh` |
| 新开终端是否自动启用 | `~/.bashrc`、`~/.zshrc` 里 `# --- office python venv begin ---` 到 `end` |
| 右键加载逻辑 | `~/.local/share/nautilus/lib/Office/nautilus_env.sh` |
| 右键菜单 / 脚本库 | `~/.local/share/nautilus/scripts` 、 `~/.local/share/nautilus/lib/Office` |
| 右键相关 apt、ImageGPS、pip 镜像 | 脚本顶部 `WITH_NAUTILUS`、`WITH_IMAGEGPS`、`PYPI_INDEX`，或 `--without-nautilus`、`--with-imagegps`、`PYPI_INDEX_URL` |
| apt / pip 包名单 | 脚本中部 `APT_CORE`、`APT_SOFT`、`APT_NAUTILUS`、`PIP_CORE_MAP` 等 |

### 三个路径分别是什么

这三个不是同一类东西。安装选定环境之后，前两个会被写成指向那个环境；第三个才是环境本体。

| 路径 | 是什么 | 谁读它 |
| --- | --- | --- |
| `~/.PythonVenv` | 默认的虚拟环境目录，里面有 `bin/python` 和装好的包。模式 2 留空时用它；模式 1 在终端、配置、activate 都没有时，有就沿用，没有就新建在这里。 | 安装脚本的最后一步；右键在前两个都没用上时，才 `source` 这里的 `bin/activate` |
| `~/.config/office/python-venv` | 一行文字，内容是环境目录的绝对路径。这台机器现在是 conda 的 `dev`。改这一行就换右键和新终端用的目录，不用改 bashrc/zshrc。 | 右键的 `nautilus_env.sh` 最先读它；`bashrc`/`zshrc` 里 office 那段也先读它 |
| `~/.python_venv_activate` | 几行 shell，用来把上面那个目录启用起来。普通 venv 是 `. "目录/bin/activate"`；conda 没有 activate 脚本，就写成 `export PATH` 和 `VIRTUAL_ENV`。当前窗口要马上用：`. ~/.python_venv_activate` | 配置文件指向的目录用不了时，右键和 shell 启动脚本退回读它 |

右键读的顺序：`~/.config/office/python-venv` 里的目录能用就停；不能用再执行 `~/.python_venv_activate`；再不行才用 `~/.PythonVenv`。文件管理器不会读 `bashrc`/`zshrc`。

* **aes\_encrypt.sh**：用于对文件进行 AES 加密的脚本。
* **encdec.sh**：此脚本用于对指定文件进行 AES-256-CBC 加密和解密
* **ArchiveAndSplit压缩分片/**：用于将大文件压缩并按指定大小进行分片的工具文件夹。

* **convert2docx**:doc和wps转为docx

* **convert2xlsx**:xls和et转为xlsx

* **CopySearchFile.py**：查找符合条件的文件并复制到指定目录的 Python 脚本。

* **duplex_print_pdf.sh**:银河麒麟系统双面打印PDF文件
* **Excel/**：处理 Excel 文件的脚本集合目录。
* **Excel2Csv.sh**：将 Excel 文件批量转换为 CSV 文件的脚本。

* **fix_filenames.py**：修复Windows->Linux系统后，文件名乱码问题。

* **fix\_long\_filenames.sh**：用于修复超出文件系统限制的长文件名或路径的脚本。

* **Gbk2Utf8.sh**：批量将文件从 GBK 编码转换为 UTF-8 编码的脚本。

* **Image\_Tools/**：图像处理相关脚本和工具的集合目录。

* **log/**：历史文件

* **move\_subdirfiles\_here.sh**：将子目录中的文件移动到当前目录的脚本。

* **NautilusScripts/**：GNOME 右键脚本。分类子目录名前缀 `▸`（如 `▸PDF`）便于和顶层动作脚本区分；顶层常用：`复制文件内容` / `复制路径` / `分别打成压缩包` / `删除空文件夹` / `保存剪贴板到文件`。

* **Office2txt.sh**：Word/Excel 批量转纯文本（保目录结构）。`./Office2txt.sh [目录|文件]` → `office_mirror/`；日志在 `office_mirror/_logs/`；缺依赖会提示安装（不自动 sudo）。

* **PDF\_Tools/**：PDF 合并、拆分、提取等工具集合目录。

* **README.md**：项目或脚本使用说明文档。
* **replace_in_files.sh**：此脚本用于批量替换当前目录下指定扩展名文件中的字符串内容。
* **removeBlankSpaceFilename.py**：用 Python 批量去除文件名中的空格的脚本。
* **removeBlankSpaceFilename.sh**：用 Bash 去除文件名中空格的脚本。
* **RenameDirectory/**：目录批量重命名工具目录。
* **rename2dirame.sh**：将文件名重命名为所在目录名的脚本。
* **RemoveDuplicatesHashFile5.0.sh**：通过哈希值查找并删除重复文件的脚本。

* **searchDocx.sh**：在 Word（默认）/ Excel（`-x`）中按关键字搜索；非交互 CLI，输出接近 grep，可管道。`./searchDocx.sh --help`

* **Word2txt.sh**：将 Word 文件批量转换为纯文本的脚本。

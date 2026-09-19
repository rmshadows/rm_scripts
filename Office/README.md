# Office

说明：处理Office文件。

作者：Ryan Yim

Github：https://github.com/rmshadows/

## 目录

* **0-Off-init.sh**：Office 依赖一键安装（**默认含 Nautilus 右键依赖**）。系统工具走 apt；**Python 库 pip→`~/.PythonVenv`**。`./0-Off-init.sh --yes`；不要右键包时加 `--without-nautilus`。

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

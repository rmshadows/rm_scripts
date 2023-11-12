# Fluxbox配置

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


#!/bin/bash
# 会生成服务文件在$HOME/Services
if ! [ -d "$HOME/Services" ];then
    mkdir "$HOME/Services"
    echo "#!/bin/bash
# 此脚本会拷贝*.service到/lib/systemd/system/
sudo cp *.service /lib/systemd/system/
sudo systemctl daemon-reload
" > "$HOME/Services/Install_Services.sh"
    chmod +x "$HOME/Services/Install_Services.sh"
fi

if ! [ -d "$HOME/Applications" ];then
    mkdir "$HOME/Applications"
fi


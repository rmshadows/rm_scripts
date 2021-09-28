#!/bin/bash
set -uex
IS_GNOME_DE="NULL"
if echo $DESKTOP_SESSION | grep "gnome" > /dev/null ;then
    IS_GNOME_DE="TRUE"
else
    echo "不是GNOME桌面环境，慎用。"
    exit 1
fi

echo $0
echo $1

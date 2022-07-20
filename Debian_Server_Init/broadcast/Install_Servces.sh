#!/bin/bash
dincludes=`ls`

for each in ${dincludes[@]}
do
    if [ -d "$each" ];then
        if [ -f "$each/$each.service" ];then
            echo "$each"
            sudo cp "$each/$each.service" /lib/systemd/system/
        fi
    fi
done
sudo systemctl daemon-reload

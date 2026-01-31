# Title

## 使用systemd

查看现有定时器：`systemctl list-timers --all`

## 使用cron

设置循环任务:

`crontab -e`

```
    sudo cp multi_nic_route.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/multi_nic_route.sh

    sudo cp multi-nic-route.service /lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable multi-nic-route.service
    sudo systemctl start multi-nic-route.service   # 或重启后自动执行
```

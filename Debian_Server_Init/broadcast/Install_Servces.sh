#!/bin/bash
cp *.service /lib/systemd/system/
sudo systemctl daemon-reload

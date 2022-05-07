#!/bin/bash
kill -9 `ps -ef | grep _live.sh | awk '{print $2}'`
ps aux | grep _live.sh

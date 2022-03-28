#!/bin/bash
# 简单粗暴删除rss后重装 要求安装有Docker
docker stop rsshub
docker rm rsshub
docker pull diygod/rsshub
docker run -d --name rsshub -p 1200:1200 diygod/rsshub





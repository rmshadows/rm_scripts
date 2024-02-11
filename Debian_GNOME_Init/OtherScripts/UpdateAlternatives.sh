#!/bin/bash
# whereis java
# 显示版本
# update-alternatives --display java
# 切换版本
# update-alternatives --config java
# update-alternatives --install /usr/bin/java java [JAVA_HOME] [优先级，比如300]
sudo update-alternatives --install /usr/bin/java java /home/???/jdk-21.0.2/bin/java 1900

#!/bin/bash

killall conky
sleep 2s

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US

conky -c $HOME/.config/conky/Altair/Altair.conf &> /dev/null &

exit

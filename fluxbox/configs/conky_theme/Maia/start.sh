#!/bin/bash

# This command will close all active conky
killall conky
sleep 2s
		
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US

# Only the config listed below will be avtivated
# if you want to combine with another theme, write the command here
conky -c $HOME/.config/conky/Maia/Maia1.conf &> /dev/null &
conky -c $HOME/.config/conky/Maia/Maia2.conf &> /dev/null &
conky -c $HOME/.config/conky/Maia/Maia3.conf &> /dev/null &

exit

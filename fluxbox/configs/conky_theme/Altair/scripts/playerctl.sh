#!/bin/bash

# Closebox73
# Simple script to get playerctl status

PCTL=$(playerctl status)

if [[ ${PCTL} == "" ]]; then
	echo "None"
else
	echo "$(playerctl metadata xesam:title) / $PCTL"
fi

exit

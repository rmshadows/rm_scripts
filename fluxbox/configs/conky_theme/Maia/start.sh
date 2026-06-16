#!/bin/bash

killall conky
sleep 2s

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US

DIR="$(cd "$(dirname "$0")" && pwd)"
conky -c "${DIR}/Maia1.conf" &> /dev/null &
conky -c "${DIR}/Maia2.conf" &> /dev/null &
conky -c "${DIR}/Maia3.conf" &> /dev/null &

exit

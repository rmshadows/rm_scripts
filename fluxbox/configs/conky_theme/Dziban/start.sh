#!/bin/bash

killall conky
sleep 2s

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US

DIR="$(cd "$(dirname "$0")" && pwd)"
conky -c "${DIR}/Dziban.conf" &> /dev/null &
conky -c "${DIR}/Dziban2.conf" &> /dev/null &

exit

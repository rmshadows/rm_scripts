#!/bin/bash

killall conky
sleep 2s

DIR="$(cd "$(dirname "$0")" && pwd)"
conky -c "${DIR}/Alsafi.conf" &> /dev/null &

exit

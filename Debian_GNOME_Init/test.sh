#!/bin/bash
IS_GNOME_DE="$USER Append"
echo $IS_GNOME_DE >> 1.txt
sed "s/$IS_GNOME_DE/ /g" 1.txt

#!/bin/bash
extn="MP4"

# for f in *.MP4;do ffmpeg -i ${f} -q 0 "${f%.*}.MTS"; done
for f in *."$extn";do
  # echo "${f}"
  ffmpeg -i ${f} -q 0 "${f%.*}.MTS";
done

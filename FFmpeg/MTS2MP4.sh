#!/bin/bash

extn="MTS"

# for f in *.MP4;do ffmpeg -i ${f} -q 0 "${f%.*}.MTS"; done
for f in *."$extn";do
  ffmpeg -i ${f} -q 0 "${f%.*}.MP4";
done

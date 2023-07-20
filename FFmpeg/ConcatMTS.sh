#!/bin/bash
# ffmpeg -f concat -safe 0 -i <(for f in *.mts; do echo "file '$PWD/${f}'"; done) -c copy All.mts

concat_file="2.txt"
out_file="ALL.MTS"

# ffmpeg -f concat -safe 0 -i "$concat_file" -c copy "$out_file"
ffmpeg -f concat -safe 0 -i <(for f in *.MTS; do echo "file '$PWD/${f}'"; done) -c copy "$out_file"

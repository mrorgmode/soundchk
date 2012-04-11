#!/bin/bash
##################################
# split_on_silence.sh
#
# Usage: 
#   split_on_silence.sh inputfile outputprefix
#
#   After a recording sessions, call script again with same prefix, and with the
#   -n flag, to post process the recorded files (normalisation, flac-conversion).
#
# Notes:
#   Will only work on distros using pulseaudio.
#
# I got this from: http://www.outflux.net/blog/archives/2009/04/19/recording-from-pulseaudio/
# and modified it slightly.
#
# Per Weijnitz <per.weijnitz@gmail.com>

IN=$1
OUT=$2

#sox $IN $OUT silence 1 0.1 7% 1 0.1 7% : newfile : restart
sox $IN $OUT silence 1 0.1 4% 1 0.1 4% : newfile : restart


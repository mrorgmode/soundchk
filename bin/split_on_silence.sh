#!/bin/bash
##################################
# split_on_silence.sh
#
# Usage: 
#   split_on_silence.sh inputfile outputprefix
#
# Per Weijnitz <per.weijnitz@gmail.com>

IN=$1
OUT=$2

#sox $IN $OUT silence 1 0.1 7% 1 0.1 7% : newfile : restart
sox $IN $OUT silence 1 0.1 4% 1 0.1 4% : newfile : restart


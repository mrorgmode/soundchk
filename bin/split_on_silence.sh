#!/bin/bash
##################################
# split_on_silence.sh
#
# Usage: 
#   split_on_silence.sh inputfile outputprefix
#
# Notes:
#   This is just a sox call.
#
# License: 
#  http://www.gnu.org/licenses/gpl-3.0.txt
#
# Per Weijnitz <per.weijnitz@gmail.com>

IN=$1
OUT=$2

#sox $IN $OUT silence 1 0.1 7% 1 0.1 7% : newfile : restart
sox $IN $OUT silence 1 0.1 4% 1 0.1 4% : newfile : restart


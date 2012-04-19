#!/bin/bash
##################################
# split_evenly.sh
#
# Usage: 
#   split_on_silence.sh inputfile outputprefix seconds
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
SIZE=$3

sox $IN $OUT trim 0 $SIZE : newfile : restart 


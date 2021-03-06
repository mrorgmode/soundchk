#!/bin/bash
##################################
# record_what_you_hear.sh
#
# Usage: 
#   record_what_you_hear.sh ( -n ) /path/and/outputprefix
#
#   After a recording sessions, call script again with same prefix, and with the
#   -n flag, to post process the recorded files (normalisation, flac-conversion).
#
# Notes:
#   Will only work on distros using pulseaudio.
#
# License: 
#  http://www.gnu.org/licenses/gpl-3.0.txt
#
# I got this from: http://www.outflux.net/blog/archives/2009/04/19/recording-from-pulseaudio/
# and modified it slightly.
#
# Per Weijnitz <per.weijnitz@gmail.com>

MODE=record

## delete files smaller than this number of bytes
SIZELIMIT=20000


if [ "$1" = "-n" ]
then
    MODE=normalise
    shift;
fi


FLAC="$1"


if [ "$MODE" = "normalise" ]
then
    echo "normalising..."
    for F in "$FLAC"*.wav
    do
	normalize-audio $F 
	flake $F -o $(dirname $F)/norm_$(basename $F | sed -e 's/.wav$//' -e 's/\.flac//').flac
	rm $F
	if [ $(stat -c '%s' $(dirname $F)/norm_$(basename $F | sed -e 's/.wav$//' -e 's/\.flac//').flac) -lt $SIZELIMIT ]
	    then
	    echo "**** removing small file "$(dirname $F)/norm_$(basename $F | sed -e 's/.wav$//' -e 's/\.flac//').flac >&2
	    rm $(dirname $F)/norm_$(basename $F | sed -e 's/.wav$//' -e 's/\.flac//').flac
	fi
    done
    exit
fi


if [ -z "$FLAC" ]; then
    echo "Usage: $0 OUTPUT.flac" >&2
    exit 1
fi
rm -f "$FLAC"


# Get sink monitor:
MONITOR=$(pactl list | egrep -A2 '^(\*\*\* )?Source #' | \
    grep 'Name: .*\.monitor$' | awk '{print $NF}' | tail -n1)
echo "set-source-mute ${MONITOR} false" | pacmd >/dev/null
 
# Record it raw, and convert to a wav
echo "Recording to $FLAC ... (when ready, normalise with: $0 -n $FLAC)"
parec -d "$MONITOR" |\
sox -t raw -r 44k -sLb 16 -c 2 - "$FLAC".wav silence 1 0.50 0.1% 1 2.0 0.5% : newfile : restart


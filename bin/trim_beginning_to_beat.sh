#!/bin/bash


IN="$1"
OUT="$2"

LIMIT="-20d"


# ## Find maximum amplitude
# MAXAMP=$(sox $IN -n stat 2>&1 | grep "Maximum amplitude:" | sed 's/^.*:[[:space:]]*//')


cp "$IN" "$OUT"

ORGSIZE=$(stat "$OUT" | grep Size | sed 's/^.*Size: \([0-9]*\).*$/\1/')
sox "$OUT" "$IN.out.wav" silence 1 0 -20d
NEWSIZE=$(stat "$IN.out.wav" | grep Size | sed 's/^.*Size: \([0-9]*\).*$/\1/')

while [ $NEWSIZE -lt $ORGSIZE ]
do
#    echo "$NEWSIZE -lt $ORGSIZE" >&2
    sox "$OUT" "$IN.out.wav" silence 1 0 $LIMIT
    ORGSIZE=$NEWSIZE
    NEWSIZE=$(stat "$IN.out.wav" | grep Size | sed 's/^.*Size: \([0-9]*\).*$/\1/')
    mv "$IN.out.wav" "$OUT"
done

exit

#!/bin/bash


IN=$1

## Find maximum amplitude
MAXAMP=$(sox $IN -n stat 2>&1 | grep "Maximum amplitude:" | sed 's/^.*:[[:space:]]*//')


cp $IN $IN.proc.wav
ORGSIZE=$(stat $IN.proc.wav | grep Size | sed 's/^.*Size: \([0-9]*\).*$/\1/')
sox $IN.proc.wav $IN.out.wav silence 1 0 -20d
NEWSIZE=$(stat $IN.out.wav | grep Size | sed 's/^.*Size: \([0-9]*\).*$/\1/')

while [ $NEWSIZE -lt $ORGSIZE ]
do
    echo "$NEWSIZE -lt $ORGSIZE" >&2
    sox $IN.proc.wav $IN.out.wav silence 1 0 -20d
    ORGSIZE=$NEWSIZE
    NEWSIZE=$(stat $IN.out.wav | grep Size | sed 's/^.*Size: \([0-9]*\).*$/\1/')
    mv $IN.out.wav $IN.proc.wav
done
echo "$NEWSIZE -lt $ORGSIZE" >&2
echo $IN.proc.wav





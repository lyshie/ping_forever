#!/bin/sh

HOST=$1
PORT=$2
PERIOD=$3

while [ 1 ]
do
    echo $(date +"[%s]") $(tcping -t "$PERIOD" "$HOST" "$PORT")
    sleep $PERIOD
done

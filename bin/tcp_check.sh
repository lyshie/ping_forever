#!/bin/sh

BIN=$( cd "$( dirname "$0" )" && pwd )
DIR=$(dirname "$BIN")
NOW=$(date -R)

LISTS=$(pgrep -a -f tcping.sh | cut -d' ' -f4-6 | tr ' ' ',' | sort | xargs)

echo "Checking ($NOW) ..."

for i in $LISTS ; do
      host=$(echo "$i" | cut -d',' -f1)
      port=$(echo "$i" | cut -d',' -f2)
    period=$(echo "$i" | cut -d',' -f3)

    hashed=$(echo -n "$host" | md5sum | cut -d ' ' -f1)
    log_file="$DIR/log/$hashed.log"
    echo "Checking $host (port = $port, period = $period seconds) .."
    printf "%80s\n" | tr " " "="
    "$DIR/bin/tcp_missing.pl" $host
    echo ""
done | mail -s "Daily TCP Ping Check ($NOW)" lyshie@mx.nthu.edu.tw

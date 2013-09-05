#!/bin/sh

BIN=$( cd "$( dirname "$0" )" && pwd )
DIR=$(dirname "$BIN")
NOW=$(date -R)

LISTS=$(pgrep -a -f "ping -D" | cut -d' ' -f4 | sort | xargs)

echo "Checking ($NOW) ..."

for i in $LISTS ; do
    hashed=$(echo -n "$i" | md5sum | cut -d ' ' -f1)
    log_file="$DIR/log/$hashed.log"
    info=$(tail -n 1 "$log_file" | grep -oP "(?<=from\s)\S*\(*.+\)*(?=:)")
    echo "Checking $i [$info] .."
    printf "%80s\n" | tr " " "="
    "$DIR/bin/missing.pl" $i | awk '
        BEGIN {
            FS=",";
        }
        {
            if ($2 > 10) {
                print;
            }
        }'
    echo ""
done | mail -s "Daily Ping Check ($NOW)" lyshie@mx.nthu.edu.tw

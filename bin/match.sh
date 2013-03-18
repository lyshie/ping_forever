#!/bin/sh

NOW=$(date --date="$2" +%s)
BIN=$( cd "$( dirname "$0" )" && pwd )
DIR=$(dirname "$BIN")

TARGET=$1
HASHED=$(echo -n "$TARGET" | md5sum | cut -d ' ' -f1)
OUTPUT_FILE="$DIR/log/$HASHED.log"

if [ -f $OUTPUT_FILE ]; then
	timeout 5 grep --color=always -A 5 -B 5 "\[$NOW\..*\]" "$OUTPUT_FILE"
fi

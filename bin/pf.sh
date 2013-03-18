#!/bin/sh

PING=$(which ping)
BIN=$( cd "$( dirname "$0" )" && pwd )
DIR=$(dirname "$BIN")

TARGET=$1
HASHED=$(echo -n "$TARGET" | md5sum | cut -d ' ' -f1)
PID_FILE="$DIR/run/$HASHED.pid"
OUTPUT_FILE="$DIR/log/$HASHED.log"

if [ -f $PID_FILE ]; then
	PID=$(cat $PID_FILE)
	kill $PID
fi

echo "Target: $TARGET"
echo "Log file: $OUTPUT_FILE"
echo "PID file: $PID_FILE"

daemonize -E LANG=C -p "$PID_FILE" -a -e "$OUTPUT_FILE" -o "$OUTPUT_FILE" "$PING" -D "$TARGET"

#!/bin/sh
./build/server &
pid="$!"
trap 'kill "$pid"' EXIT

sleep 1

if [ -n "$POLLER_MODE" ]; then
    POLLER_FLAG="-Djdk.pollerMode=$POLLER_MODE"
else
    POLLER_FLAG=
fi

i=1
while ./build/client $POLLER_FLAG; do
	echo "Attempt $((i++))"
done

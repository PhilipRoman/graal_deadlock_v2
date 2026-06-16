#!/bin/sh
./build/server &
pid="$!"
trap 'kill "$pid"' EXIT

i=1
while ./build/client; do
	echo "Attempt $((i++))"
done

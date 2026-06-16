#!/usr/bin/env bash
set -eux

CLASSES=build/classes

mkdir -p "$CLASSES"

# Compile
javac -d "$CLASSES" src/main/java/Client.java src/main/java/Server.java

COMMON_ARGS=(
    --no-fallback
    -march=x86-64-v3
    -cp "$CLASSES"
    -H:Path=build
)

"$JAVA_HOME/bin/native-image" "${COMMON_ARGS[@]}" -H:Name=client Client
"$JAVA_HOME/bin/native-image" "${COMMON_ARGS[@]}" -H:Name=server Server

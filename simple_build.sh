#!/usr/bin/env bash
set -eux

CLASSES=build/classes
PATCH_CLASSES=build/patch-classes
PATCH_WORK=build/patch-work

mkdir -p "$CLASSES" "$PATCH_CLASSES" "$PATCH_WORK/sun/nio/ch"

# Compile no-op native library used by the EPollPoller patch
gcc -shared -fPIC -O2 -o build/libnoop.so src/noop/noop.c

# Compile application
javac -d "$CLASSES" src/main/java/Client.java src/main/java/Server.java

# Extract and patch JDK sources from this GraalVM's bundled source zip.
# .orig files are kept in the work dir for reference/diffing.
unzip -p "$JAVA_HOME/lib/src.zip" "java.base/sun/nio/ch/EPollPoller.java" \
    > "$PATCH_WORK/sun/nio/ch/EPollPoller.java.orig"
cp "$PATCH_WORK/sun/nio/ch/EPollPoller.java.orig" \
   "$PATCH_WORK/sun/nio/ch/EPollPoller.java"
patch "$PATCH_WORK/sun/nio/ch/EPollPoller.java" src/patch/EPollPoller.patch

# Compile patched EPollPoller against this GraalVM's java.base
"$JAVA_HOME/bin/javac" \
    --patch-module java.base="$PATCH_WORK" \
    -d "$PATCH_CLASSES" \
    "$PATCH_WORK/sun/nio/ch/EPollPoller.java"

# Copy native-image metadata onto the classpath so native-image picks it up
cp -r src/native-image/META-INF "$CLASSES/"

COMMON_ARGS=(
    --no-fallback
    -march=x86-64-v3
    -cp "$CLASSES"
    -H:Path=build
    # Inject patched EPollPoller into java.base at image-build time
    -J--patch-module=java.base="$PATCH_CLASSES"
)

"$JAVA_HOME/bin/native-image" "${COMMON_ARGS[@]}" -H:Name=client Client
"$JAVA_HOME/bin/native-image" "${COMMON_ARGS[@]}" -H:Name=server Server

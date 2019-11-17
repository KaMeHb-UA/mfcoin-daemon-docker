#!/bin/sh
set -e

mkdir -p "$DATA_DIR"
chmod 700 "$DATA_DIR"
chown -R mfcdaemon "$DATA_DIR"

if [ "$DEBUG" = 'true' ]; then
    apt install -y gdb
    sudo -u mfcdaemon gdb -ex=r --args ./mfcoind "$@" -datadir="$DATA_DIR"
else
    sudo -u mfcdaemon ./mfcoind "$@" -datadir="$DATA_DIR"
fi

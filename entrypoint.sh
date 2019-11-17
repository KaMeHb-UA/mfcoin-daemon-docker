#!/bin/sh
set -e

chmod 700 /data
chown -R mfcdaemon /data /home/mfcdaemon

if [ "$DEBUG" = 'true' ]; then
    apt update
    apt install -y gdb
    sudo -u mfcdaemon gdb -ex=r --args ./mfcoind "$@"
else
    sudo -u mfcdaemon ./mfcoind "$@"
fi

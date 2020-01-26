#!/bin/sh

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/' |                                  # Pluck JSON value
    cut -c 3-                                                       # Remove leading "v."
}

LATEST_RELEASE=$(get_latest_release MFrCoin/MFCoin)
PLATFORMS="linux/arm,linux/arm64,linux/amd64"
DH_NAME="kamehb/mfc-wallet-daemon"

docker buildx build -t "$DH_NAME" -t "$DH_NAME:latest" -t "$DH_NAME:$LATEST_RELEASE" "--platform=$PLATFORMS" . --push

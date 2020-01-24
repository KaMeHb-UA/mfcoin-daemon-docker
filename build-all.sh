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

# minimal
#docker buildx build --build-arg WALLET=false --build-arg UPNPC=false -t "$DH_NAME:minimal" -t "$DH_NAME:latest-minimal" -t "$DH_NAME:$LATEST_RELEASE-minimal" "--platform=$PLATFORMS" . --push

# new_db
docker buildx build --build-arg USE_OLD_BERKLEYDB=false -t "$DH_NAME:new_db" -t "$DH_NAME:latest-new_db" -t "$DH_NAME:$LATEST_RELEASE-new_db" "--platform=$PLATFORMS" . --push

# without_upnpc
docker buildx build --build-arg UPNPC=false -t "$DH_NAME:without_upnpc" -t "$DH_NAME:latest-without_upnpc" -t "$DH_NAME:$LATEST_RELEASE-without_upnpc" "--platform=$PLATFORMS" . --push

# new_db-without_upnpc
docker buildx build --build-arg USE_OLD_BERKLEYDB=false --build-arg UPNPC=false -t "$DH_NAME:new_db-without_upnpc" -t "$DH_NAME:latest-new_db-without_upnpc" -t "$DH_NAME:$LATEST_RELEASE-new_db-without_upnpc" "--platform=$PLATFORMS" . --push

# without_wallet
#docker buildx build --build-arg WALLET=false -t "$DH_NAME:without_wallet" -t "$DH_NAME:latest-without_wallet" -t "$DH_NAME:$LATEST_RELEASE-without_wallet" "--platform=$PLATFORMS" . --push

# latest
docker buildx build -t "$DH_NAME" -t "$DH_NAME:latest" -t "$DH_NAME:$LATEST_RELEASE" "--platform=$PLATFORMS" . --push

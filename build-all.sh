#!/bin/sh
PLATFORMS="--platform=linux/arm,linux/arm64,linux/amd64"
DH_NAME="kamehb/mfc-wallet-daemon"

# minimal
docker buildx build --build-arg WALLET=false --build-arg UPNPC=false -t "$DH_NAME:minimal" "$PLATFORMS" . --push

# new_db
docker buildx build --build-arg USE_OLD_BERKLEYDB=false -t "$DH_NAME:new_db" "$PLATFORMS" . --push

# without_upnpc
docker buildx build --build-arg UPNPC=false -t "$DH_NAME:without_upnpc" "$PLATFORMS" . --push

# new_db-without_upnpc
docker buildx build --build-arg USE_OLD_BERKLEYDB=false --build-arg UPNPC=false -t "$DH_NAME:new_db-without_upnpc" "$PLATFORMS" . --push

# without_wallet
docker buildx build --build-arg WALLET=false -t "$DH_NAME:without_wallet" "$PLATFORMS" . --push

# latest
docker buildx build -t "$DH_NAME" "$PLATFORMS" . --push

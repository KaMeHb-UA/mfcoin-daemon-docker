# MFCoin daemon
This repository contains a dockerfile for mfcoin daemon

## Images naming
This section describes what the naming rules used in autobuilds on Docker Hub.

Modificators:
```
without_wallet
without_upnpc
new_db
new_db-without_upnpc
minimal
```
Versioning:
like on GitHub stripping leading `v.`  
For example release `v.3.0.0.2` will be named as `3.0.0.2`. Also there is `latest` version (used by default) that is compiled on every commit from the default git branch.

Versions and modificators are not required for naming. If version is not specified `latest` will be used. If modificator is not specified no one will be used (walled on berkleydb4.8 and miniupnpc are included)

Main naming rule: `kamehb/mfc-wallet-daemon:VERSION(-MODIFICATOR)`

Examples:
```
kamehb/mfc-wallet-daemon # equivalent of kamehb/mfc-wallet-daemon:latest
kamehb/mfc-wallet-daemon:3.0.0.2
kamehb/mfc-wallet-daemon:new_db # equivalent of kamehb/mfc-wallet-daemon:latest-new_db
kamehb/mfc-wallet-daemon:3.0.0.2-new_db
```

## Build by yourself
There is no special prerequisites for building standard image (contains wallet functionality based on berkleydb4.8 and firewall-jumping functionality). To build it:
```sh
docker build .
```

### Args
Additionally you can use build args to customize the process:

#### VERSION
You can define what version to use. For example, `3.0.0.2` will switch git source tree to the branch `tags/v.3.0.0.2`. Default: `latest`
```sh
VERSION=3.0.0.2
```

#### WALLET
You can disable wallet functionality (useful for server nodes). Acceptable values = `true`, `false`. Default: `true`
```
WALLET=false
```

#### UPNPC
You can disable firewall-jumping functionality. Acceptable values = `true`, `false`. Default: `true`
```
UPNPC=false
```

#### USE_OLD_BERKLEYDB
Additionally, you can use the newest BerkleyDB distribution. This may increase build speed and daemon runtime performance and/or security (?) but will break daemon compatibility with `wallet.dat`'s based on old db. By default, daemon compiles **with** old db support, but you can redefine it. Acceptable values = `true`, `false`. Default: `true`
```
USE_OLD_BERKLEYDB=false
```

### Build example
Build minimal 3.0.0.2 version:
```
docker build . --build-arg WALLET=false --build-arg UPNPC=false --build-arg VERSION=3.0.0.2
```
In example above there is no difference between BerkleyDB versions — wallet isn't used so BerkleyDB isn't installed

## Run
You may feel free to use this image whatever you want, but there is need in mounting data volume and specifying its path in the container to store daemon data outside the container. If you want it of course. In examples we will use `/mfc-data` as a permanent storage. Besides there is no need in special security or network flags, etc.

### Simply run container with permanent storage
```
docker run -it -v /mfc-data:/data kamehb/mfc-wallet-daemon
```

### Run minimal container as a rpc server
```
docker run -it -v /mfc-data:/data -p 22825:22825 kamehb/mfc-wallet-daemon:minimal -rpcport=22825 -rpcuser=RPC_USER -rpcpassword=RPC_PASS -reindex -txindex -rpcallowip=0.0.0.0/0
```
Note: running rpc server with mapping to host network is not needed in general. If it applicable just setup rpc server and services that using it on dedicated network. The simpliest way to achieve is described below in docker-compose config

### Run with docker-compose
There is simple config example for services that requires mfcoin daemon to work with
```
version: '3.3'

networks:
  mfcservices:

services:
  daemon:
    image: mfc-wallet-daemon:3.0.0.2-minimal
    networks:
      - mfcservices
    volumes:
      - ./data/daemon:/data
    command:
      - -rpcport=22825
      - -rpcuser=${RPC_USER}
      - -rpcpassword=${RPC_PASS}
      - -reindex
      - -txindex
      - -rpcallowip=0.0.0.0/0
  myservice:
    image: myimage
    networks:
      - mfcservices
    volumes:
      - ./data/myservice:/data
    command:
      - connect
      - -user=${RPC_USER}
      - -pass=${RPC_PASS}
      - daemon:22825
```
Note: the best way to store user and password for rpc service in docker-compose is .env file. Do not forget to chmod it to 600

## Debug
There is also available `DEBUG` environment variable for this image. Set it to `true` to download gdb and start new gdb session in runtime

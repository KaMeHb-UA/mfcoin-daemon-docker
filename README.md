# MFCoin daemon

This repository contains a dockerfile for mfcoin daemon

## Building
There is no special prerequisites for building standard image (contains wallet functionality based on berkleydb4.8 and firewall-jumping functionality). To build it:
```sh
docker build .
```
### Args
Additionally you can use build args to customize the process:
#### VERSION
You can define what version to use. For example, 3.0.0.2. This will switch git source tree to the branch tags/v.3.0.0.2. Default: latest
```sh
VERSION=3.0.0.2
```
#### WALLET
You can disable wallet functionality (helpful for server nodes). Acceptable values = true,false. Default


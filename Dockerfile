FROM alpine AS berkleydb

RUN apk add --no-cache build-base curl && \
    mkdir /db && \
    cd /db && \
    curl https://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz | tar xzf - && \
    sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i /db/db-4.8.30.NC/dbinc/atomic.h && \
    mkdir -p /opt/db && \
    cd ./*/build_unix && \
    ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=/opt/db && \
    make -j$(nproc --all) && \
    make install && \
    rm -rf /opt/db/docs /db && \
    apk del --no-cache build-base curl

FROM alpine AS builder

ARG VERSION=latest
ARG WALLET=true
ARG UPNPC=true
ARG USE_OLD_BERKLEYDB=true

COPY --from=berkleydb /opt/db /opt/db

RUN variant() { export tmp="$(mktemp)"; if [ "$1" = "$2" ]; then echo "$3" > "$tmp"; else echo "$4" > "$tmp"; fi; . "$tmp"; rm -f "$tmp"; } && \
    apk add --no-cache binutils git autoconf pkgconfig automake build-base libtool boost-dev libevent-dev boost-static libevent-static && \
    apk add --no-cache openssl-dev openssl-libs-static --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main && \
    git clone https://github.com/MFrcoin/MFCoin.git && \
    cd /MFCoin && \
    git pull && \
    variant "$VERSION" latest 'echo' "git checkout tags/v.$VERSION" && \
    git submodule update --init --recursive && \
    variant "$WALLET" true "variant $USE_OLD_BERKLEYDB false 'apk add --no-cache db-dev' ''" '' && \
    variant "$UPNPC" true 'apk add --no-cache miniupnpc-dev' '' && \
    cd /MFCoin && \
    export LDFLAGS="-static-libgcc -static-libstdc++ -static" && \
    export LIBTOOL_APP_LDFLAGS=-all-static && \
    ./autogen.sh && \
    ./configure \
        "$(variant $WALLET$USE_OLD_BERKLEYDB truetrue 'echo LDFLAGS=$LDFLAGS -L/opt/db/lib/ -L/usr/lib/' 'echo LDFLAGS=$LDFLAGS -L/usr/lib/')" \
        "$(variant $WALLET$USE_OLD_BERKLEYDB truetrue 'echo CPPFLAGS=-I/opt/db/include/ -I/usr/include/boost/' 'echo CPPFLAGS=-I/usr/include/boost/')" \
        $(variant "$WALLET$USE_OLD_BERKLEYDB" truefalse 'echo --with-incompatible-bdb' '') \
        $(variant "$WALLET" false 'echo --disable-wallet' '') \
        $(variant "$UPNPC" false 'echo --without-miniupnpc' '') \
        --prefix=/usr \
        --disable-tests \
        --disable-bench \
        --disable-ccache \
        --disable-shared \
        --without-gui && \
    make -j$(nproc --all) && \
    make install && \
    strip /usr/bin/mfcoind && \
    apk del --no-cache binutils git autoconf pkgconfig automake build-base libtool boost-dev libevent-dev boost-static libevent-static openssl-dev openssl-libs-static $(variant "$WALLET$USE_OLD_BERKLEYDB" truefalse 'echo db-dev' '') && \
    rm -rf /usr/bin/mfcoin-* /db /MFCoin /opt/db/include /opt/db/bin /var/cache /usr/share/man /usr/lib/libmfcoinconsensus* /usr/include/mfcoinconsensus*


FROM alpine

COPY --from=builder /usr/bin/mfcoind /usr/bin

USER guest

WORKDIR /data

ENTRYPOINT [ "/usr/bin/mfcoind" ]

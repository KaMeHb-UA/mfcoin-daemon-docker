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

RUN apk add --no-cache git autoconf pkgconfig automake build-base libtool boost-dev libevent-dev openssl-dev

RUN git clone https://github.com/MFrcoin/MFCoin.git

RUN variant() { export tmp="$(mktemp)"; if [ "$1" = "$2" ]; then echo "$3" > "$tmp"; else echo "$4" > "$tmp"; fi; . "$tmp"; rm -f "$tmp"; } && \
    cd /MFCoin && \
    git pull && \
    variant "$VERSION" latest 'echo' "git checkout tags/v.$VERSION" && \
    git submodule update --init --recursive && \
    variant "$WALLET" true "variant $USE_OLD_BERKLEYDB false 'apk add --no-cache db-dev' ''" '' && \
    variant "$UPNPC" true 'apk add --no-cache miniupnpc-dev' '' && \
    cd /MFCoin && \
    export LDFLAGS="-static-libgcc -static-libstdc++ -static" && \
    export LIBTOOL_APP_LDFLAGS=-all-static && \
    export CFLAGS="-lstdc++" && \
    export CXXFLAGS="-std=c++11" && \
    ./autogen.sh && \
    ./configure \
        "$(variant $WALLET$USE_OLD_BERKLEYDB truetrue 'echo LDFLAGS=$LDFLAGS -L/opt/db/lib/' '')" \
        $(variant "$WALLET$USE_OLD_BERKLEYDB" truetrue 'echo CPPFLAGS=-I/opt/db/include/' '') \
        $(variant "$WALLET$USE_OLD_BERKLEYDB" truefalse 'echo --with-incompatible-bdb' '') \
        $(variant "$WALLET" false 'echo --disable-wallet' '') \
        $(variant "$UPNPC" false 'echo --without-miniupnpc' '') \
        --prefix=/usr \
        --disable-tests \
        --disable-bench \
        --disable-ccache \
        --disable-shared \
        --with-boost=/usr/include/boost \
        --with-boost-libdir=/usr/lib \
        --without-gui && \
    make -j$(nproc --all) && \
    make install && \
    apk del --no-cache git autoconf pkg-config automake libtool build-base boost-dev libevent-dev openssl-dev db-dev && \
    rm -rf /usr/bin/mfcoin-* /db /MFCoin /opt/db/include /opt/db/bin /var/cache /usr/share/man /usr/lib/libmfcoinconsensus* /usr/include/mfcoinconsensus* && \
    strip /usr/bin/mfcoind


FROM alpine

COPY --from=builder /usr/bin/mfcoind /usr/bin

RUN mkdir /lib64 && \
    ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
    ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2
#     && \
#    apk add --no-cache boost-filesystem=1.65 boost-system=1.65 boost-program_options=1.65 boost-thread=1.65 boost-chrono=1.65 miniupnpc=1.9 libevent=2.1.8 libgcc

USER guest

WORKDIR /data

ENTRYPOINT [ "/usr/bin/mfcoind" ]

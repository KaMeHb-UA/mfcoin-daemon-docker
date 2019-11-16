FROM alpine

ARG VERSION=latest
ARG WALLET=true
ARG UPNPC=true
ARG USE_OLD_BERKLEYDB=true

RUN variant() { export tmp="$(mktemp)"; if [ "$1" = "$2" ]; then echo "$3" > "$tmp"; else echo "$4" > "$tmp"; fi; . "$tmp"; rm -f "$tmp"; } && \
    apk add --no-cache git autoconf automake libtool build-base curl boost boost-dev libevent libevent-dev libressl libressl-dev linux-headers && \
    git clone --recursive https://github.com/MFrcoin/MFCoin.git && \
    cd /MFCoin && \
    variant "$VERSION" latest 'echo' "git checkout tags/v.$VERSION" && \
    variant "$WALLET" true "variant $USE_OLD_BERKLEYDB true 'mkdir /db && cd /db && curl https://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz | tar xzf - && sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i /db/db-4.8.30.NC/dbinc/atomic.h && mkdir -p /opt/db && cd ./*/build_unix && ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=/opt/db && make -j$(nproc --all) && make install && rm -rf /opt/db/docs' 'echo USING_NEW_BERKLEYDB && apk add --no-cache db db-dev db-c++'" '' && \
    variant "$UPNPC" true 'apk add --no-cache miniupnpc miniupnpc-dev' '' && \
    cd /MFCoin && \
    ./autogen.sh && \
    ls /opt/db/* && \
    ./configure \
        $(variant "$WALLET$USE_OLD_BERKLEYDB" truetrue 'echo LDFLAGS=-L/opt/db/lib/' '') \
        $(variant "$WALLET$USE_OLD_BERKLEYDB" truetrue 'echo CPPFLAGS=-I/opt/db/include/' '') \
        $(variant "$WALLET$USE_OLD_BERKLEYDB" truefalse 'echo --with-incompatible-bdb' '') \
        $(variant "$WALLET" false 'echo --disable-wallet' '') \
        $(variant "$UPNPC" false 'echo --without-miniupnpc' '') \
        --prefix=/opt/mfcoin \
        --disable-tests \
        --disable-bench \
        --disable-ccache \
        --without-gui && \
    make -j$(nproc --all) && \
    make install && \
    strip /opt/mfcoin/bin/mfcoind && \
    cp -r genesis.dat genesis-test.dat genesis-reg.dat utxo_snapshot /opt/mfcoin/ && \
    apk del --no-cache git autoconf automake libtool build-base curl boost-dev libevent-dev libressl-dev miniupnpc-dev db-dev db-c++ linux-headers && \
    rm -rf /opt/mfcoin/bin/mfcoin-* /db /MFCoin /opt/db/include /opt/db/bin /var/cache /opt/mfcoin/include /opt/mfcoin/lib /opt/mfcoin/share /opt/mfcoin/utxo_snapshot

WORKDIR /opt/mfcoin/bin

ENTRYPOINT [ "/opt/mfcoin/bin/mfcoind" ]

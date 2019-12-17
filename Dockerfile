FROM alpine AS berkleydb

RUN apk add --no-cache build-base curl

# Download sources and some patching
RUN mkdir /db && \
    mkdir -p /opt/db && \
    cd /db && \
    curl https://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz | tar xzf - && \
    sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i /db/db-4.8.30.NC/dbinc/atomic.h && \
    curl 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' > /db/db-4.8.30.NC/dist/config.guess

WORKDIR /db/db-4.8.30.NC/build_unix

RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=/opt/db

RUN make -j$(nproc --all) && \
    make install


FROM alpine AS builder

ARG VERSION=latest
ARG WALLET=true
ARG UPNPC=true
ARG USE_OLD_BERKLEYDB=true

COPY --from=berkleydb /opt/db /opt/db

# deps
RUN apk add --no-cache binutils git autoconf pkgconfig automake build-base libtool boost-dev libevent-dev boost-static libevent-static miniupnpc-dev db-dev && \
    apk add --no-cache openssl-dev openssl-libs-static --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main

RUN git clone https://github.com/MFrcoin/MFCoin.git

WORKDIR /MFCoin

RUN if ! [ "$VERSION" = latest ]; then \
        git checkout "tags/v.$VERSION" \
    fi

RUN git submodule update --init --recursive

RUN export LDFLAGS="-static-libgcc -static-libstdc++ -static"
RUN export LIBTOOL_APP_LDFLAGS=-all-static

RUN ./autogen.sh

# flags
RUN if [ "$WALLET" = true ]; then \
        if [ "$USE_OLD_BERKLEYDB" = true ]; then \
            export LDFLAGS="$LDFLAGS -L/opt/db/lib/" \
            export CPPFLAGS="$CPPFLAGS -I/opt/db/include/" \
        else \
            export NEW_WALLET=--with-incompatible-bdb \
        fi \
    else \
        export WITHOUT_WALLET=--disable-wallet \
    fi
RUN if [ "$UPNPC" = false ]; \
        export WITHOUT_UPNPC=--without-miniupnpc \
    fi
RUN export LDFLAGS="$LDFLAGS -L/usr/lib/"
RUN export CPPFLAGS="$CPPFLAGS -I/usr/include/boost/"

RUN ./configure \
        LDFLAGS="$LDFLAGS" \
        CPPFLAGS="$CPPFLAGS" \
        "$NEW_WALLET" \
        "$WITHOUT_WALLET" \
        "$WITHOUT_UPNPC" \
        --prefix=/usr \
        --disable-tests \
        --disable-bench \
        --disable-ccache \
        --disable-shared \
        --without-gui

RUN make -j$(nproc --all) && \
    make install && \
    strip /usr/bin/mfcoin*

FROM alpine

COPY --from=builder /usr/bin/mfcoind /usr/bin

USER guest

WORKDIR /data

ENTRYPOINT [ "/usr/bin/mfcoind" ]

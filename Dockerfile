FROM debian AS berkleydb

RUN apt update && \
    apt install -y build-essential curl libc6-dev

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


FROM debian AS builder

ARG VERSION=latest
ARG WALLET=true
ARG UPNPC=true
ARG USE_OLD_BERKLEYDB=true

COPY --from=berkleydb /opt/db /opt/db

RUN apt update && \
    apt install -y build-essential libc6-dev binutils git autoconf pkg-config automake libtool libdb-dev libdb++-dev libboost-all-dev libssl-dev libminiupnpc-dev libevent-dev

RUN git clone https://github.com/KaMeHb-UA/MFCoin.git

WORKDIR /MFCoin

RUN if ! [ "$VERSION" = latest ]; then \
        git checkout "tags/v.$VERSION"; \
    fi

RUN git submodule update --init --recursive

RUN echo -n "-static-libgcc -static-libstdc++ -static" > /ldflags
RUN echo -n -all-static > /ltaldflags

RUN LDFLAGS="$(cat /ldflags)" LIBTOOL_APP_LDFLAGS="$(cat /ltaldflags)" ./autogen.sh

RUN echo "-ldl" > /cppflags

# flags
RUN if [ "$WALLET" = true ]; then \
        if [ "$USE_OLD_BERKLEYDB" = true ]; then \
            echo -n " -L/opt/db/lib/" >> /ldflags; \
            echo -n " -I/opt/db/include/" >> /cppflags; \
        else \
            echo -n --with-incompatible-bdb > /newdbflag; \
            echo -n " -I/usr/include/" >> /cppflags; \
        fi \
    else \
        echo -n --disable-wallet > /nowalletflag; \
    fi
RUN if [ "$UPNPC" = false ]; then \
        echo -n --without-miniupnpc > /noupnpcflag; \
    fi
RUN echo -n " -L/usr/lib/" >> /ldflags
RUN echo -n " -I/usr/include/boost/" >> /cppflags

RUN export LDFLAGS="$(cat /ldflags)" && \
    export CPPFLAGS="$(cat /cppflags)" && \
    export LIBTOOL_APP_LDFLAGS="$(cat /ltaldflags)" && \
    export NEW_DB="$(cat /newdbflag)" && \
    export WITHOUT_WALLET="$(cat /nowalletflag)" && \
    export WITHOUT_UPNPC="$(cat /noupnpcflag)" && \
    export CFLAGS="-static -static-libgcc" && \
    ./configure \
        LDFLAGS="$LDFLAGS" \
        CPPFLAGS="$CPPFLAGS $CFLAGS" \
        CFLAGS="$CFLAGS" \
        "$NEW_DB" \
        "$WITHOUT_WALLET" \
        "$WITHOUT_UPNPC" \
        --prefix=/usr \
        --disable-tests \
        --disable-bench \
        --disable-ccache \
        --disable-shared \
        --without-gui

RUN make -j$(nproc --all) && \
    make install
# && \
#    strip /usr/bin/mfcoin*

FROM alpine

COPY --from=builder /usr/bin/mfcoind /usr/bin

RUN apk add --no-cache libc6-compat

RUN apk add --no-cache curl

RUN apk add --no-cache gdb

USER guest

WORKDIR /data

ENTRYPOINT [ "/usr/bin/mfcoind" ]

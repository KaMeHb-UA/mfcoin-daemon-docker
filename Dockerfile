FROM ubuntu:bionic

ARG VERSION=latest
ARG WALLET=true
ARG UPNPC=true
ARG USE_OLD_BERKLEYDB=true

RUN variant() { export tmp="$(mktemp)"; if [ "$1" = "$2" ]; then echo "$3" > "$tmp"; else echo "$4" > "$tmp"; fi; . "$tmp"; rm -f "$tmp"; } && \
    mkdir -p /home/mfcdaemon /data && \
    ln -s /data /home/mfcdaemon/.MFC && \
    cp -rp /var/cache /var_cache && \
    useradd -r mfcdaemon && \
    apt update && \
    apt install -y sudo git autoconf pkg-config automake libtool build-essential curl libboost-atomic1.65.1 libboost-chrono1.65.1 libboost-container1.65.1 libboost-context1.65.1 libboost-coroutine1.65.1 libboost-date-time1.65.1 libboost-fiber1.65.1 libboost-filesystem1.65.1 libboost-graph-parallel1.65.1 libboost-graph1.65.1 libboost-iostreams1.65.1 libboost-locale1.65.1 libboost-log1.65.1 libboost-math1.65.1 libboost-mpi-python1.65.1 libboost-mpi1.65.1 libboost-numpy1.65.1 libboost-program-options1.65.1 libboost-python1.65.1 libboost-random1.65.1 libboost-regex1.65.1 libboost-serialization1.65.1 libboost-signals1.65.1 libboost-stacktrace1.65.1 libboost-system1.65.1 libboost-test1.65.1 libboost-thread1.65.1 libboost-timer1.65.1 libboost-type-erasure1.65.1 libboost-wave1.65.1 libboost-all-dev libevent-2.1-6 libevent-pthreads-2.1-6 libevent-dev libssl1.0.0 libssl-dev && \
    git clone https://github.com/MFrcoin/MFCoin.git && \
    cd /MFCoin && \
    variant "$VERSION" latest 'echo' "git checkout tags/v.$VERSION" && \
    git submodule update --init --recursive && \
    variant "$WALLET" true "variant $USE_OLD_BERKLEYDB true 'mkdir /db && cd /db && curl https://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz | tar xzf - && sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i /db/db-4.8.30.NC/dbinc/atomic.h && mkdir -p /opt/db && cd ./*/build_unix && ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=/opt/db && make -j$(nproc --all) && make install && rm -rf /opt/db/docs' 'apt install -y libdb5.3 libdb5.3++ libdb++-dev'" '' && \
    variant "$UPNPC" true 'apt install -y libminiupnpc10 libminiupnpc-dev' '' && \
    cd /MFCoin && \
    ./autogen.sh && \
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
    cp genesis.dat genesis-test.dat genesis-reg.dat /opt/mfcoin/ && \
    apt remove -y git autoconf automake libtool build-essential curl libboost-all-dev libevent-dev libminiupnpc-dev libdb++-dev libssl-dev && \
    apt autoremove -y && \
    rm -rf /opt/mfcoin/bin/mfcoin-* /db /MFCoin /opt/db/include /opt/db/bin /var/cache /opt/mfcoin/include /opt/mfcoin/lib /opt/mfcoin/share && \
    mv /var_cache /var/cache

COPY entrypoint.sh /

WORKDIR /opt/mfcoin/bin

ENTRYPOINT [ "/entrypoint.sh" ]

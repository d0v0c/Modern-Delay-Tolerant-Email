FROM ubuntu:24.04

# Avoid waiting for input during interactive installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    postfix \
    dovecot-core \
    dovecot-imapd \
    dovecot-lmtpd \
    rsyslog \
    mailutils \
    procps \
    nano \
    iputils-ping \
    net-tools \
    iproute2 \
    automake \
    autoconf \
    libtool \
    m4 \
    gcc \
    make \
    tcpdump \
    pkg-config \
    libglib2.0-dev \
    libssl-dev \
    software-properties-common gpg-agent \
    cmake \
    meson \
    python3-venv python3-pytest python3-dnslib \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /usr/local/src
COPY --chmod=755 mbedtls-2.28.8/ ./mbedtls-2.28.8/
COPY --chmod=755 ION-DTN/ ./ION-DTN/
COPY --chmod=755 gmime-3.2.15/ ./gmime-3.2.15/
COPY --chmod=755 c-ares-1.34.4/ ./c-ares-1.34.4/
COPY --chmod=755 bpmail/ ./bpmail/

#安装ION-DTN和加密套件
WORKDIR /usr/local/src/mbedtls-2.28.8
RUN make SHARED=1 && make install

WORKDIR /usr/local/src/ION-DTN
RUN autoreconf -fi \
	&& ./configure --enable-crypto-mbedtls --enable-bpsec-debugging \
    && make \
    && make install \
    && ldconfig

#安装bpmail和其依赖gmime、c-ares
WORKDIR /usr/local/src/gmime-3.2.15
RUN ./configure --prefix=/usr --disable-static && make
RUN make install

WORKDIR /usr/local/src/c-ares-1.34.4
RUN mkdir build \
    && cd build \
    && cmake -D CMAKE_INSTALL_PREFIX=/usr .. \
    && make \
    && make install

WORKDIR /usr/local/src/bpmail
RUN meson setup build \
    && meson compile -C build \
    && meson install -C build

#配置postfix+dovecot
WORKDIR /app
COPY --chmod=755 mail-server.sh .

EXPOSE 25 143

CMD ["./mail-server.sh"]

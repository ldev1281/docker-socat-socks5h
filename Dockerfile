FROM debian:bookworm AS builder

ARG DEBFULLNAME="Your Name"
ARG DEBEMAIL="your@email.com"

ENV DEBFULLNAME=${DEBFULLNAME}
ENV DEBEMAIL=${DEBEMAIL}

RUN echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list && \
    echo "deb-src http://deb.debian.org/debian bookworm main" >> /etc/apt/sources.list && \
    echo "deb http://security.debian.org/debian-security bookworm-security main" >> /etc/apt/sources.list && \
    echo "deb-src http://security.debian.org/debian-security bookworm-security main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y \
    devscripts \
    build-essential \
    fakeroot \
    dpkg-dev \
    curl \
    ca-certificates \
    gnupg \
    git \
    wget \
    equivs \
    vim

WORKDIR /build

RUN apt-get source proxychains && \
    cd proxychains-* && \
    mk-build-deps -i -r -t "apt-get -y" debian/control

COPY proxychains-sockshost-fqdn-support.patch /build/

RUN cd proxychains-* && \
    cp /build/proxychains-sockshost-fqdn-support.patch debian/patches/ && \
    echo "proxychains-sockshost-fqdn-support.patch" >> debian/patches/series && \
    dch --local ~custom --distribution bookworm "Add FQDN support via patch"

RUN cd proxychains-* && \
    dpkg-buildpackage -us -uc

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    socat \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/*.deb /tmp/

RUN apt-get update && \
    apt-get install -y /tmp/libproxychains3_*.deb /tmp/proxychains_*.deb && \
    apt-get clean && rm -rf /tmp/*.deb /var/lib/apt/lists/*

COPY --chmod=755 usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

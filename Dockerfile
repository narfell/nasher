ARG NWN_ASSETS="8193.35"

FROM ghcr.io/urothis/nwserver:$NWN_ASSETS as nwnassets

FROM alpine:latest as downloader

ARG NASHER_RELEASE="0.20.0"
ARG NWNSC_RELEASE="v1.1.5"
ARG NEVERWINTER_NIM_RELEASE="1.5.9"
 
ENV NASHER_RELEASE=$NASHER_RELEASE
ENV NWNSC_RELEASE=$NWNSC_RELEASE
ENV NEVERWINTER_NIM_RELEASE=$NEVERWINTER_NIM_RELEASE

RUN apk add \
        unzip \
        curl

RUN mkdir -p binaries
RUN curl \
        -L "https://github.com/nwneetools/nwnsc/releases/download/${NWNSC_RELEASE}/nwnsc-linux-${NWNSC_RELEASE}.zip" \
        -o nwnsc.zip \
    && unzip nwnsc.zip \
    && mv nwnsc binaries/nwnsc
RUN curl \
        -L "https://github.com/niv/neverwinter.nim/releases/download/${NEVERWINTER_NIM_RELEASE}/neverwinter.linux.amd64.zip" \
        -o neverwinter.linux.amd64.zip \
    && unzip neverwinter.linux.amd64.zip \
    && mv nwn_* binaries/
RUN curl \
        -L "https://github.com/squattingmonk/nasher/releases/download/${NASHER_RELEASE}/nasher_linux.tar.gz" \
        -o nasher_linux.tar.gz \
    && tar -xf nasher_linux.tar.gz \
    && mv nasher_linux/nasher binaries/

FROM --platform=linux/amd64 ubuntu:23.10

ARG NASHER_USER_ID=1002
ENV NASHER_USER_ID=$NASHER_USER_ID

COPY --from=nwnassets /nwn /nwn
COPY --from=downloader /binaries/* /usr/local/bin/

RUN apt update \
    && apt upgrade -y \
    && apt install \
        git \
        libsqlite3-dev \
        -y

RUN adduser nasher \
        --disabled-password \
        --gecos "" \
        --uid ${NASHER_USER_ID} \
    && usermod -aG sudo nasher

WORKDIR /nasher
RUN chown -R nasher:nasher /nwn /usr/local/bin/nwnsc /nasher
USER nasher
RUN nasher config --nssFlags:"-n /nwn/data -o" \
    && nasher config --installDir:"/nasher/install" \
    && nasher config --userName:"nasher"
RUN bash -c "mkdir -pv /nasher/install/{erf,hak,modules,tlk}"

ENTRYPOINT [ "nasher" ]
CMD [ "--help" ]

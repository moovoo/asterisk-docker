FROM debian:buster as builder

ARG asterisk_version=19-current
ARG make_build_args=-j8
ARG menuselect_options="--enable codec_opus \
                        --enable CORE-SOUNDS-EN-WAV --enable CORE-SOUNDS-EN-GSM \
                        --enable EXTRA-SOUNDS-EN-WAV --enable EXTRA-SOUNDS-EN-GSM \
                        --enable MOH-OPSOUND-WAV --enable MOH-OPSOUND-GSM"

ADD https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-$asterisk_version.tar.gz /
RUN tar zxvf asterisk-$asterisk_version.tar.gz && cd asterisk-*/contrib/scripts/ && \
    apt-get update && DEBIAN_FRONTEND=noninteractive ./install_prereq install && cd ../.. && \
    ./configure && \
    if [ -n "$menuselect_options" ]; then \
    make menuselect.makeopts && menuselect/menuselect $menuselect_options menuselect.makeopts; \
    fi && \
    make $make_build_args all && make install && make samples

FROM debian:buster

RUN apt-get update && apt-get install -y openssl gir1.2-gmime-3.0 libasound2 libcodec2-0.8.1 libcurl4 libedit2 libgsm1 \
    libical3 libiksemel3 libjack-jackd2-0 libjansson4 liblua5.2-0 libneon27 libsnmp-base libsnmp30 libodbc1 libogg0 \
    libopus0 libosptk4 libportaudio2 libpq5 libradcli4 libresample1 libspandsp2 libspeex1 libspeexdsp1 libsqlite3-0 \
    libsrtp2-1 libsybdb5 libtiff5 libunbound8 liburiparser1 libvorbis0a libvorbisenc2 libvorbisfile3 libxslt1.1 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /etc/asterisk/ /etc/asterisk/
COPY --from=builder /usr/sbin/ /usr/sbin/
COPY --from=builder /usr/lib/asterisk/ /usr/lib/asterisk/
COPY --from=builder /usr/lib/libasterisk* /usr/lib/
COPY --from=builder /run/asterisk/ /run/asterisk/
COPY --from=builder /var/lib/asterisk/ /var/lib/asterisk/
COPY --from=builder /var/spool/asterisk/ /var/spool/asterisk/
COPY --from=builder /var/cache/asterisk/ /var/cache/asterisk/
COPY --from=builder /var/log/asterisk /var/log/asterisk

CMD ["/usr/sbin/asterisk", "-c", "-vvvv", "-g"]

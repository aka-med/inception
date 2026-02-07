FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    vsftpd \
 && rm -rf /var/lib/apt/lists/*

COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 21

CMD ["/entrypoint.sh"]

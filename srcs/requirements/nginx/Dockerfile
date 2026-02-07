FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx openssl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

ARG DOMAIN_NAME

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/nginx/ssl/inception.key \
      -out /etc/nginx/ssl/inception.crt \
      -subj "/C=MA/ST=SALE/L=SALE/O=42/CN=${DOMAIN_NAME}"

COPY conf/nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]

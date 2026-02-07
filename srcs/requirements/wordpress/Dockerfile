FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar mariadb-client \
    php-fpm php-mysql php-curl php-mbstring php-xml php-zip php-redis \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://wordpress.org/latest.tar.gz | tar -xz -C /tmp \
 && mv /tmp/wordpress /wordpress \
 && curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x /usr/local/bin/wp

# php-fpm listen on TCP 9000 (auto-detect PHP version)
RUN sed -i "s|^listen = .*|listen = 0.0.0.0:9000|" /etc/php/*/fpm/pool.d/www.conf \
 && mkdir -p /var/www/html

COPY ./tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

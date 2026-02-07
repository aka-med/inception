FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    php-fpm php-mysql \
 && rm -rf /var/lib/apt/lists/*

# Download Adminer into a fixed path (no volumes needed)
RUN mkdir -p /var/www/adminer \
 && curl -fsSL -o /var/www/adminer/adminer.php \
    http://www.adminer.org/latest.php

# php-fpm listen on TCP 9000 for nginx
RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/*/fpm/pool.d/www.conf

CMD ["php-fpm8.2", "-F"]

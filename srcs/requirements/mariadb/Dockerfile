FROM debian:bookworm

RUN apt-get update \
 && apt-get install -y mariadb-server --no-install-recommends\
 && rm -rf /var/lib/apt/lists/*

# Make MariaDB accept connections from other containers on the Docker network
RUN sed -i 's/^[#[:space:]]*bind-address.*/bind-address = 0.0.0.0/' \
    /etc/mysql/mariadb.conf.d/50-server.cnf

COPY ./tools/init_db.sh /init_db.sh

RUN chmod +x /init_db.sh

CMD ["/init_db.sh"]

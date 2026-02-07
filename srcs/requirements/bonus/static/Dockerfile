FROM debian:bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/nginx/sites-enabled/default

# Nginx site config + static files
COPY conf/static.conf /etc/nginx/sites-available/static.conf
RUN ln -s /etc/nginx/sites-available/static.conf /etc/nginx/sites-enabled/static.conf

COPY site/ /var/www/html/
RUN chmod -R o+r /var/www/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

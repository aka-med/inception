#!/bin/bash
set -eu

: "${WORDPRESS_DB_PASSWORD_FILE:?WORDPRESS_DB_PASSWORD_FILE is missing}"
: "${WP_ADMIN_PASSWORD_FILE:?WP_ADMIN_PASSWORD_FILE is missing}"
: "${WP_USER_PASSWORD_FILE:?WP_USER_PASSWORD_FILE is missing}"

: "${WORDPRESS_DB_HOST:?WORDPRESS_DB_HOST is missing}"
: "${WORDPRESS_DB_USER:?WORDPRESS_DB_USER is missing}"
: "${WORDPRESS_DB_NAME:?WORDPRESS_DB_NAME is missing}"

: "${WP_SITE_URL:?WP_SITE_URL is missing}"
: "${WP_SITE_TITLE:?WP_SITE_TITLE is missing}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER is missing}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is missing}"

: "${WP_USER:?WP_USER is missing}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is missing}"


[ -f "$WORDPRESS_DB_PASSWORD_FILE" ] || { echo "Missing $WORDPRESS_DB_PASSWORD_FILE"; exit 1; }
[ -f "$WP_ADMIN_PASSWORD_FILE" ]     || { echo "Missing $WP_ADMIN_PASSWORD_FILE"; exit 1; }
[ -f "$WP_USER_PASSWORD_FILE" ]      || { echo "Missing $WP_USER_PASSWORD_FILE"; exit 1; }

WORDPRESS_DB_PASSWORD="$(cat "$WORDPRESS_DB_PASSWORD_FILE")"
WP_ADMIN_PASSWORD="$(cat "$WP_ADMIN_PASSWORD_FILE")"
WP_USER_PASSWORD="$(cat "$WP_USER_PASSWORD_FILE")"


# copy WP to volume if empty
if [ ! -f /var/www/html/index.php ]; then
  cp -a /wordpress/. /var/www/html/
  chown -R www-data:www-data /var/www/html
fi

cd /var/www/html

# wait DB (bounded: 30s max) - using mariadb-admin
i=0
until MYSQL_PWD="$WORDPRESS_DB_PASSWORD" mariadb-admin ping -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" --silent; do
  i=$((i+1)); [ "$i" -ge 30 ] && echo "DB not ready" && exit 1
  sleep 1
done


# wp-config.php once
[ ! -f wp-config.php ] && wp config create \
  --dbname="$WORDPRESS_DB_NAME" --dbuser="$WORDPRESS_DB_USER" \
  --dbpass="$WORDPRESS_DB_PASSWORD" --dbhost="$WORDPRESS_DB_HOST" --allow-root

wp config has FS_METHOD --allow-root >/dev/null 2>&1 || \
  wp config set FS_METHOD direct --type=constant --allow-root

# install once
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  wp core install --url="$WP_SITE_URL" --title="$WP_SITE_TITLE" \
    --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" --skip-email --allow-root
fi

# 2nd user once
wp user get "$WP_USER" --allow-root >/dev/null 2>&1 || \
  wp user create "$WP_USER" "$WP_USER_EMAIL" --user_pass="$WP_USER_PASSWORD" --role=editor --allow-root


# --- Redis bonus (safe to run on every boot, but we'll make it mostly "once") ---
# Ensure wp-config has Redis host (does nothing if already set)
wp config has WP_REDIS_HOST --allow-root >/dev/null 2>&1 || \
  wp config set WP_REDIS_HOST "redis" --type=constant --allow-root

# Install+activate plugin only if missing
wp plugin is-installed redis-cache --allow-root >/dev/null 2>&1 || \
  wp plugin install redis-cache --activate --allow-root

# Enable drop-in only if not already enabled
[ -f /var/www/html/wp-content/object-cache.php ] || \
  wp redis enable --allow-root
# --- end Redis bonus ---


exec php-fpm8.2 -F

#!/bin/sh
set -eu

: "${MARIADB_DATABASE:?Missing MARIADB_DATABASE}"
: "${MARIADB_USER:?Missing MARIADB_USER}"
: "${MARIADB_PASSWORD_FILE:?Missing MARIADB_PASSWORD_FILE}"
: "${MARIADB_ROOT_PASSWORD_FILE:?Missing MARIADB_ROOT_PASSWORD_FILE}"

# ensure secret files are readable
[ -r "$MARIADB_PASSWORD_FILE" ] || { echo "[init] Password file not readable"; exit 1; }
[ -r "$MARIADB_ROOT_PASSWORD_FILE" ] || { echo "[init] Root password file not readable"; exit 1; }

MARIADB_PASSWORD="$(cat "$MARIADB_PASSWORD_FILE")"
MARIADB_ROOT_PASSWORD="$(cat "$MARIADB_ROOT_PASSWORD_FILE")"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ -d "/var/lib/mysql/$MARIADB_DATABASE" ]; then
  echo "Database already exists"
else
  echo "[init] First run: initializing database files..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql

  echo "[init] Starting MariaDB temporarily..."
  mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/tmp/mysql.sock &
  pid="$!"

  for i in $(seq 1 30); do
    mariadb-admin --socket=/tmp/mysql.sock ping >/dev/null 2>&1 && break
    sleep 1
  done

  mariadb-admin --socket=/tmp/mysql.sock ping >/dev/null 2>&1 || {
    echo "[init] MariaDB failed to start"
    exit 1
  }
  echo "[init] Creating DB + user..."
  mariadb --socket=/tmp/mysql.sock -u root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

  echo "[init] Stopping temporary MariaDB..."
  mariadb-admin --socket=/tmp/mysql.sock -u root -p"${MARIADB_ROOT_PASSWORD}" shutdown
  wait "$pid"
fi

# ---- 3) Always start MariaDB normally (foreground) ----
echo "[init] Starting MariaDB normally..."
exec mariadbd --user=mysql --datadir=/var/lib/mysql

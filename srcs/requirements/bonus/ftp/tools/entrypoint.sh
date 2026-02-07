#!/bin/sh
set -eu

: "${FTP_USER:?FTP_USER is missing}"
: "${FTP_PASS_FILE:?FTP_PASS_FILE is missing}"

[ -f "$FTP_PASS_FILE" ]     || { echo "Missing file: $FTP_PASS_FILE"; exit 1; }
FTP_PASS="$(cat "$FTP_PASS_FILE")"

# The shared WordPress files volume is mounted here
mkdir -p /var/www/html

# Create user if not exists (simple + restart-safe)
if ! id "$FTP_USER" >/dev/null 2>&1; then
  # Put user in www-data group
  adduser --disabled-password --gecos "" --home /var/www/html --no-create-home --ingroup www-data "$FTP_USER"
fi

echo "$FTP_USER:$FTP_PASS" | chpasswd

# Give FTP user write access to WP files
chown -R "$FTP_USER":www-data /var/www/html
chmod -R g+rwX /var/www/html

# Minimal vsftpd config (hardcode passive ports to keep env minimal)
cat > /etc/vsftpd.conf <<'EOF'
listen=YES
listen_ipv6=NO
background=NO

anonymous_enable=NO
local_enable=YES
write_enable=YES

chroot_local_user=YES
allow_writeable_chroot=YES
local_root=/var/www/html

# Passive mode ports (must match docker-compose ports)
pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21110

secure_chroot_dir=/var/run/vsftpd/empty

# Often needed in containers
seccomp_sandbox=NO
EOF

# Create vsftpd secure chroot dir (needed in containers)
mkdir -p /var/run/vsftpd/empty
chmod 555 /var/run/vsftpd/empty

exec /usr/sbin/vsftpd /etc/vsftpd.conf

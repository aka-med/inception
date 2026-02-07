# Developer Documentation

This guide explains how to set up, build, maintain, and extend the Inception project.
It is intended for developers who need to understand the project internals.

---

## Table of Contents

- [Project Setup from Scratch](#project-setup-from-scratch)
- [Build and Launch Procedure](#build-and-launch-procedure)
- [Containers, Networks, and Volumes](#containers-networks-and-volumes)
- [Useful Development Commands](#useful-development-commands)

---

## Project Setup from Scratch

### Prerequisites

Ensure the following tools are installed on your development machine:

| Tool           | Minimum Version  | Purpose                       |
| -------------- | ---------------- | ----------------------------- |
| Docker         | 20.10+           | Container runtime             |
| Docker Compose | 2.0+ (V2 syntax) | Multi-container orchestration |
| Make           | 3.81+            | Build automation              |
| Git            | 2.0+             | Version control               |

On Debian/Ubuntu:

```bash
# Install prerequisites
sudo apt update && sudo apt install -y ca-certificates curl make git

# Remove old/conflicting Docker packages from distro repos (safe to run even if not installed)
sudo apt remove -y docker.io docker-cli containerd runc docker-buildx 2>/dev/null || true

# Detect distro (debian or ubuntu)
. /etc/os-release
DISTRO="$ID"   # "debian" or "ubuntu"

# Add Docker's official GPG key and repository
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL "https://download.docker.com/linux/${DISTRO}/gpg" \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/${DISTRO} ${VERSION_CODENAME} stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Compose plugin
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER  # Log out and back in after this
```

> **Note**: The script auto-detects whether you are on **Debian** or **Ubuntu** via
> `/etc/os-release` and uses the matching Docker repository.
> The removal step prevents dpkg conflicts between Debian-packaged Docker components
> (e.g. `docker-buildx`) and Docker's official packages.

### Cloning the Repository

```bash
git clone <repository-url> inception
cd inception
```

### Directory Structure

```
inception/
├── Makefile                      # Build automation
├── README.md                     # Project overview and subject comparisons
├── USER_DOC.md                   # End-user documentation
├── DEV_DOC.md                    # This file — developer documentation
├── secrets/                      # Docker secrets (passwords — git-ignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── ftp_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                      # Non-sensitive environment variables
    ├── docker-compose.yml        # Service definitions
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/init_db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/nginx.conf
        ├── wordpress/
        │   ├── Dockerfile
        │   └── tools/entrypoint.sh
        └── bonus/
            ├── adminer/
            │   └── Dockerfile
            ├── cadvisor/
            │   └── Dockerfile
            ├── ftp/
            │   ├── Dockerfile
            │   └── tools/entrypoint.sh
            ├── redis/
            │   └── Dockerfile
            └── static/
                ├── Dockerfile
                ├── conf/static.conf
                └── site/
                    ├── index.html
                    └── style.css
```

### Configuration Files

#### `srcs/.env` — Environment Variables

This file contains non-sensitive configuration values used by `docker-compose.yml`:

```dotenv
DOMAIN_NAME=makarkao.42.fr
LOGIN=makarkao

# Database (non-sensitive values only)
MARIADB_DATABASE=wordpress
MARIADB_USER=wp_userr
MARIADB_PASSWORD_FILE=/run/secrets/db_password
MARIADB_ROOT_PASSWORD_FILE=/run/secrets/db_root_password
WORDPRESS_DB_HOST=mariadb

# WordPress users (non-sensitive values only)
WP_ADMIN_USER=wpd_makarkao
WP_ADMIN_EMAIL=wpd_makarkao@42.fr
WP_USER=ed_makarkao
WP_USER_EMAIL=ed_makarkao@42.fr
WP_SITE_TITLE=inception
WP_SITE_URL=https://makarkao.42.fr
WP_ADMIN_PASSWORD_FILE=/run/secrets/wp_admin_password
WP_USER_PASSWORD_FILE=/run/secrets/wp_user_password

# FTP
FTP_USER=ftpmakarkao
FTP_PASS_FILE=/run/secrets/ftp_password
```

**Key points:**

- `LOGIN` is used in volume device paths (`/home/${LOGIN}/data/`)
- `DOMAIN_NAME` is passed as a build argument to NGINX for SSL certificate generation
- `*_FILE` variables point to Docker secret mount paths inside the containers
- No passwords are stored here — they go in `secrets/` files

#### `secrets/` Directory — Docker Secrets

This directory contains sensitive credentials, one per file. These files are listed in `.gitignore` and must not be committed:

| File                      | Purpose                                      |
| ------------------------- | -------------------------------------------- |
| `db_password.txt`       | Password for the MariaDB user (`wp_userr`) |
| `db_root_password.txt`  | Password for the MariaDB root user           |
| `wp_admin_password.txt` | Password for the WordPress admin user        |
| `wp_user_password.txt`  | Password for the WordPress editor user       |
| `ftp_password.txt`      | Password for the FTP user                    |

**Creating secrets files:**

```bash
echo "secure_db_password_here" > secrets/db_password.txt
echo "secure_root_password_here" > secrets/db_root_password.txt
echo "secure_wp_admin_password_here" > secrets/wp_admin_password.txt
echo "secure_wp_user_password_here" > secrets/wp_user_password.txt
echo "secure_ftp_password_here" > secrets/ftp_password.txt
```

#### Important Configuration Files

| File                                                | Purpose                                                                              |
| --------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `srcs/requirements/nginx/conf/nginx.conf`         | NGINX server block: TLS settings, FastCGI proxying to WordPress and Adminer          |
| `srcs/requirements/mariadb/tools/init_db.sh`      | MariaDB first-run initialization (creates DB, user, sets root password)              |
| `srcs/requirements/wordpress/tools/entrypoint.sh` | WordPress first-run setup (WP-CLI config, core install, user creation, Redis plugin) |
| `srcs/requirements/bonus/ftp/tools/entrypoint.sh` | FTP user creation and vsftpd configuration                                           |
| `srcs/requirements/bonus/static/conf/static.conf` | NGINX server block for the static site (port 80)                                     |

### Host Configuration

Add the domain to your hosts file:

```bash
echo "127.0.0.1 makarkao.42.fr" | sudo tee -a /etc/hosts
```

---

## Build and Launch Procedure

### How the Makefile Works

The Makefile provides a simple interface to Docker Compose. It references the compose file at `./srcs/docker-compose.yml` and manages host data directories at `/home/makarkao/data`.

```makefile
COMPOSE_FILE := ./srcs/docker-compose.yml
DATA_DIR := /home/makarkao/data
WORDPRESS_DATA := $(DATA_DIR)/wp_data
MARIADB_DATA := $(DATA_DIR)/db_data

all: build up           # Default target: build then start

build:                   # Build all Docker images
    docker compose -f $(COMPOSE_FILE) build

up: create_dirs          # Start containers (after creating data dirs)
    docker compose -f $(COMPOSE_FILE) up -d

down:                    # Stop and remove containers
    docker compose -f $(COMPOSE_FILE) down

stop:                    # Stop containers (preserve state)
    docker compose -f $(COMPOSE_FILE) stop

start:                   # Start stopped containers
    docker compose -f $(COMPOSE_FILE) start

create_dirs:             # Create host data directories
    @mkdir -p $(WORDPRESS_DATA)
    @mkdir -p $(MARIADB_DATA)

clean: down              # Remove container data
    @sudo rm -rf $(WORDPRESS_DATA)/*
    @sudo rm -rf $(MARIADB_DATA)/*

fclean:                  # Complete cleanup
    @docker compose -f $(COMPOSE_FILE) down -v
    @sudo rm -rf $(DATA_DIR)
    @docker system prune -af
```

### Build Targets Summary

| Command         | Action                                                 |
| --------------- | ------------------------------------------------------ |
| `make`        | Build all images and start the stack                   |
| `make build`  | Build images only (no start)                           |
| `make up`     | Create data directories and start containers           |
| `make down`   | Stop and remove containers (data preserved)            |
| `make stop`   | Stop containers without removing                       |
| `make start`  | Restart stopped containers                             |
| `make clean`  | Stop containers and clear data directory contents      |
| `make fclean` | Full cleanup (removes volumes, images, data directory) |

### First-Time Build Process

1. **Build images**: Docker reads each Dockerfile and creates images
2. **Create data directories**: `/home/makarkao/data/wp_data` and `/home/makarkao/data/db_data`
3. **Start containers**: Services start in dependency order (MariaDB + Redis → WordPress → NGINX)
4. **Database initialization**: MariaDB runs `init_db.sh` — initializes data files, starts a temporary instance, creates the database and user, then restarts in foreground mode
5. **WordPress setup**: `entrypoint.sh` copies WordPress files to the volume, waits for MariaDB, generates `wp-config.php`, installs the site, creates the editor user, and configures the Redis cache plugin

---

## Containers, Networks, and Volumes

### Services Overview

| Service       | Image Name              | Base            | Role                                                     |
| ------------- | ----------------------- | --------------- | -------------------------------------------------------- |
| `nginx`     | `nginx:inception`     | Debian Bookworm | TLS termination, reverse proxy for WordPress and Adminer |
| `wordpress` | `wordpress:inception` | Debian Bookworm | PHP-FPM 8.2, WordPress CMS, WP-CLI                       |
| `mariadb`   | `mariadb:inception`   | Debian Bookworm | MySQL-compatible database server                         |
| `redis`     | `redis:inception`     | Debian Bookworm | In-memory object cache (64 MB, allkeys-lru eviction)     |
| `adminer`   | `adminer:inception`   | Debian Bookworm | PHP-FPM 8.2 serving Adminer (database admin UI)          |
| `ftp`       | `ftp:inception`       | Debian Bookworm | vsftpd file server for WordPress volume                  |
| `cadvisor`  | `cadvisor:inception`  | Debian Bookworm | Container resource monitoring (cAdvisor v0.56.2 binary)  |
| `static`    | `static:inception`    | Debian Bookworm | NGINX serving a static HTML/CSS resume site              |

### Service Dependencies

```
nginx
  └── depends_on: wordpress

wordpress
  ├── depends_on: mariadb
  └── depends_on: redis

ftp
  └── depends_on: wordpress
```

All other services (adminer, cadvisor, static, redis, mariadb) have no explicit `depends_on`.

### Network Configuration

All services connect to a single Docker bridge network:

```yaml
networks:
  inception_net:
```

**Inter-service communication:**

- Services resolve each other by service name (e.g., `mariadb`, `redis`, `wordpress`, `adminer`)
- Internal communication uses Docker's built-in DNS on the bridge network
- Only specific ports are published to the host:

| Service  | Host Port   | Container Port | Purpose           |
| -------- | ----------- | -------------- | ----------------- |
| nginx    | 443         | 443            | HTTPS entry point |
| ftp      | 21          | 21             | FTP control       |
| ftp      | 21100-21110 | 21100-21110    | FTP passive data  |
| cadvisor | 8000        | 8080           | Monitoring web UI |
| static   | 3031        | 80             | Static site       |

WordPress, MariaDB, Redis, and Adminer do **not** expose any ports to the host. They are only reachable through the internal network (or via NGINX reverse proxy for WordPress and Adminer).

### Volume Configuration

Two named volumes with bind mounts are defined:

```yaml
volumes:
  db_data:
    driver: local
    driver_opts:
      type: none
      device: /home/${LOGIN}/data/db_data
      o: bind
  wp_data:
    driver: local
    driver_opts:
      type: none
      device: /home/${LOGIN}/data/wp_data
      o: bind
```

**Volume usage:**

| Volume      | Mount Point        | Services       | Access Mode         | Purpose               |
| ----------- | ------------------ | -------------- | ------------------- | --------------------- |
| `db_data` | `/var/lib/mysql` | mariadb        | read-write          | Database files        |
| `wp_data` | `/var/www/html`  | wordpress, ftp | read-write          | WordPress files       |
| `wp_data` | `/var/www/html`  | nginx          | **read-only** | Serving static assets |

**cAdvisor** also mounts several host paths as **read-only** for monitoring purposes:

- `/:/rootfs:ro`, `/sys:/sys:ro`, `/var/lib/docker:/var/lib/docker:ro`, `/var/run:/var/run:ro`

**Data persistence:**

- Data survives container restarts and `make down`
- `make clean` clears the contents of both data directories but preserves the directories themselves
- `make fclean` removes the entire `/home/makarkao/data` directory, Docker volumes, and prunes all images

### Secrets Mounting

Secrets are declared as file-based Docker secrets in `docker-compose.yml`:

```yaml
secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
  wp_user_password:
    file: ../secrets/wp_user_password.txt
  ftp_password:
    file: ../secrets/ftp_password.txt
```

**How services consume secrets:**

Services declare which secrets they need and receive `*_FILE` environment variables pointing to the mount path. Entrypoint scripts read the actual password from the file at runtime:

```bash
# Example from WordPress entrypoint
WORDPRESS_DB_PASSWORD="$(cat "$WORDPRESS_DB_PASSWORD_FILE")"
```

| Service   | Secrets Used                                                 |
| --------- | ------------------------------------------------------------ |
| mariadb   | `db_password`, `db_root_password`                        |
| wordpress | `db_password`, `wp_admin_password`, `wp_user_password` |
| ftp       | `ftp_password`                                             |

---

## Useful Development Commands

### Viewing Container Status

```bash
# List running containers
docker compose -f srcs/docker-compose.yml ps

# List all containers (including stopped)
docker compose -f srcs/docker-compose.yml ps -a
```

### Inspecting Logs

```bash
# All containers
docker compose -f srcs/docker-compose.yml logs

# Specific service
docker compose -f srcs/docker-compose.yml logs wordpress

# Follow logs in real-time
docker compose -f srcs/docker-compose.yml logs -f nginx

# Last 100 lines
docker compose -f srcs/docker-compose.yml logs --tail=100 mariadb
```

### Entering a Container Shell

```bash
# WordPress container
docker compose -f srcs/docker-compose.yml exec wordpress bash

# MariaDB container
docker compose -f srcs/docker-compose.yml exec mariadb bash

# NGINX container
docker compose -f srcs/docker-compose.yml exec nginx bash

# Redis container
docker compose -f srcs/docker-compose.yml exec redis bash
```

### Database Access

```bash
# Connect to MariaDB from inside the container
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u wp_userr -p wordpress

# Or using the root account
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u root -p
```

### WordPress CLI

```bash
# Run WP-CLI commands inside the WordPress container
docker compose -f srcs/docker-compose.yml exec wordpress wp --allow-root user list
docker compose -f srcs/docker-compose.yml exec wordpress wp --allow-root plugin list
docker compose -f srcs/docker-compose.yml exec wordpress wp --allow-root cache flush
docker compose -f srcs/docker-compose.yml exec wordpress wp --allow-root redis status
```

### Volume and Network Inspection

```bash
# List volumes
docker volume ls | grep inception

# Inspect a volume
docker volume inspect srcs_db_data
docker volume inspect srcs_wp_data

# View volume data on host
ls -la /home/makarkao/data/db_data
ls -la /home/makarkao/data/wp_data

# Inspect the Docker network
docker network ls | grep inception
docker network inspect srcs_inception_net
```

### Image Management

```bash
# List project images
docker images | grep inception

# Rebuild a specific service
docker compose -f srcs/docker-compose.yml build wordpress

# Rebuild without cache
docker compose -f srcs/docker-compose.yml build --no-cache nginx
```

### Cleanup Commands

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes (CAUTION: may delete data)
docker volume prune

# Full system cleanup (CAUTION)
docker system prune -af
```



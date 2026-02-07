*This project has been created as part of the 42 curriculum by makarkao.*

# Inception

## Description

Inception is a system administration project that uses Docker to create a complete web
infrastructure from scratch. The goal is to set up multiple interconnected services, each
running in its own container, orchestrated with Docker Compose.

This project implements a full LEMP-like stack with the following **mandatory services**:

- **NGINX** — Reverse proxy with TLSv1.2/TLSv1.3, the sole entry point on port 443
- **WordPress** — PHP-FPM application server for the WordPress CMS
- **MariaDB** — Database server for WordPress data

Additionally, the following **bonus services** are included:

- **Redis** — Object cache for improved WordPress performance
- **Adminer** — Web-based database management tool (proxied through NGINX at `/adminer/`)
- **FTP** — File transfer server (vsftpd) pointing to the WordPress volume
- **cAdvisor** — Container monitoring and performance analysis
- **Static site** — A simple HTML/CSS personal resume page (non-PHP, served by its own NGINX instance)

All containers are built from Debian Bookworm base images with custom Dockerfiles.
No pre-built images (other than the base OS) are used.

---

## Instructions

### Prerequisites

- Docker and Docker Compose (V2) installed on the host machine
- `make` utility installed
- The domain `makarkao.42.fr` must resolve to your local IP (add to `/etc/hosts` if needed)

### Quick Start

1. **Clone the repository** and navigate to the project root:

   ```bash
   git clone <repository-url> inception
   cd inception
   ```

2. **Create the secrets files** in the `secrets/` directory with your passwords:

   ```bash
   echo "your_db_password" > secrets/db_password.txt
   echo "your_db_root_password" > secrets/db_root_password.txt
   echo "your_wp_admin_password" > secrets/wp_admin_password.txt
   echo "your_wp_user_password" > secrets/wp_user_password.txt
   echo "your_ftp_password" > secrets/ftp_password.txt
   ```

3. **Add the domain to your hosts file** (if not already done):

   ```bash
   echo "127.0.0.1 makarkao.42.fr" | sudo tee -a /etc/hosts
   ```

4. **Build and run all containers**:

   ```bash
   make
   ```

   This will:

   - Create data directories at `/home/makarkao/data/`
   - Build all Docker images
   - Start all containers in detached mode

5. **Access the website**:

   Open your browser and navigate to:

   - WordPress site: `https://makarkao.42.fr`
   - WordPress admin: `https://makarkao.42.fr/wp-admin`
   - Adminer: `https://makarkao.42.fr/adminer/`
   - cAdvisor: `http://localhost:8000`
   - Static site: `http://localhost:3031`

### Stopping the Project

```bash
make down      # Stop and remove containers (data preserved)
make stop      # Stop containers without removing them
make start     # Start previously stopped containers
```

### Cleaning Up

```bash
make clean     # Stop containers and clear data directories
make fclean    # Full clean: remove volumes, containers, and prune all images
```

---

## Resources

### Official Documentation

- **Docker**: [docs.docker.com](https://docs.docker.com/) — Container platform documentation
- **Docker Compose**: [docs.docker.com/compose](https://docs.docker.com/compose/) — Multi-container orchestration
- **NGINX**: [nginx.org/en/docs](https://nginx.org/en/docs/) — Web server and reverse proxy
- **WordPress**: [developer.wordpress.org](https://developer.wordpress.org/) — CMS development resources
- **MariaDB**: [mariadb.com/kb](https://mariadb.com/kb/) — Database server documentation
- **Redis**: [redis.io/docs](https://redis.io/docs/) — In-memory data store
- **WP-CLI**: [wp-cli.org](https://wp-cli.org/) — Command-line interface for WordPress
- **vsftpd**: [security.appspot.com/vsftpd.html](https://security.appspot.com/vsftpd.html) — FTP server
- **cAdvisor**: [github.com/google/cadvisor](https://github.com/google/cadvisor) — Container monitoring

### Additional Tutorials

- Docker Best Practices: [docs.docker.com/develop/develop-images/dockerfile_best-practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- TLS/SSL with NGINX: [nginx.org/en/docs/http/configuring_https_servers.html](https://nginx.org/en/docs/http/configuring_https_servers.html)

### AI Usage in This Project

AI tools (such as GitHub Copilot and ChatGPT) were used to assist with:

- **Documentation writing**: Generating and refining README.md, USER_DOC.md, and DEV_DOC.md
- **Prompt refinement**: Improving prompts to produce clearer, more relevant outputs
- **Configuration debugging**: Understanding NGINX FastCGI configuration and Docker networking issues
- **Best practices research**: Learning about Docker secrets, PID 1 handling, and container security

All AI-generated content was reviewed, tested, and validated by the project author.

---

## Project Description

### How Docker Is Used in This Project

This project leverages Docker to containerize each service in an isolated environment.
Docker Compose orchestrates all containers, manages their networks, volumes, and dependencies.

The infrastructure is defined declaratively in `srcs/docker-compose.yml`, allowing the
entire stack to be built, started, stopped, and destroyed with simple commands.

Key characteristics:

- Each service has its own Dockerfile in `srcs/requirements/` (mandatory) or `srcs/requirements/bonus/` (bonus)
- All containers connect via a single private Docker bridge network (`inception_net`)
- Data persistence is achieved through named Docker volumes backed by host-directory bind mounts
- Sensitive credentials are managed using Docker secrets (files in `secrets/`, mounted at `/run/secrets/` inside containers)
- Non-sensitive environment variables are loaded from `srcs/.env`

### Architecture Overview

```
                    Internet / Browser
                           │
                           ▼-----------------------
                  ┌─────────────────┐              |
                  │     NGINX       │ :443 (TLS)   |
                  │  (reverse proxy)│              |
                  └────────┬────────┘              |
                           │                       |
              ┌────────────┼                        |
              │            │                        |
              ▼            ▼                        |
        ┌───────────┐ ┌───────────┐                 |
        │ WordPress │ │  Adminer  │                 |
        │ (php-fpm) │ │ (php-fpm) │                 |
        └─────┬─────┘ └─────┬─────┘                 |
              │              │                      |
              ├──────────────┤                      |
              │              │                      |
              ▼              ▼                      |
        ┌───────────┐ ┌───────────┐                 |
        │  MariaDB  │ │   Redis   │                 |
        │ (database)│ │  (cache)  │                 |
        └───────────┘ └───────────┘                 |
                        |---------------------------|
                        ▼                           ▼
   ┌───────────┐  ┌───────────┐            ┌───────────┐
   │    FTP    │  │ cAdvisor  │            │   Static  │
   │ (vsftpd)  │  │(monitoring)│:8080      │  (nginx)  │:80
   │   :21     │  │   :8000   │            │   :3031   │
   └───────────┘  └───────────┘            └───────────┘
```

- NGINX reverse-proxies WordPress (FastCGI on port 9000) and Adminer (FastCGI on port 9000) from a single HTTPS entry point.
- Static, cAdvisor, and FTP expose their own host ports directly.
- All containers are on the `inception_net` bridge network.

### Comparisons

#### Virtual Machines vs Docker

| Aspect                   | Virtual Machines                       | Docker Containers                      |
| ------------------------ | -------------------------------------- | -------------------------------------- |
| **Isolation**      | Full OS isolation via hypervisor       | Process-level isolation via namespaces |
| **Resource usage** | Heavy (each VM runs a full OS)         | Lightweight (shares host kernel)       |
| **Startup time**   | Minutes                                | Seconds                                |
| **Image size**     | Gigabytes                              | Megabytes                              |
| **Use case**       | Running different OS, strong isolation | Microservices, fast deployments        |

**In this project**: Docker containers are used instead of VMs for their lightweight nature
and fast startup. The project itself is meant to run inside a Virtual Machine (as required
by the 42 subject), but the services are containerized with Docker rather than being
individual VMs. All containers share the host's Linux kernel but remain isolated.

#### Secrets vs Environment Variables

| Aspect               | Environment Variables                       | Docker Secrets                                            |
| -------------------- | ------------------------------------------- | --------------------------------------------------------- |
| **Storage**    | Stored in `.env` file or shell            | Stored in separate files, mounted at runtime              |
| **Visibility** | Visible in `docker inspect`, process list | Only accessible inside the container at `/run/secrets/` |
| **Security**   | Less secure (easily exposed in logs)        | More secure (not in environment, not in images)           |
| **Use case**   | Non-sensitive configuration                 | Passwords, API keys, credentials                          |

**In this project**: Both are used appropriately:

- `srcs/.env` contains non-sensitive configuration (domain name, usernames, database name, site title)
- `secrets/` directory contains sensitive passwords (five files), declared as Docker secrets in `docker-compose.yml` and mounted read-only at `/run/secrets/` inside containers
- Entrypoint scripts read passwords from `*_FILE` paths (e.g. `MARIADB_PASSWORD_FILE=/run/secrets/db_password`), so passwords never appear as environment variable values

#### Docker Network vs Host Network

| Aspect                                  | Docker Network                               | Host Network                          |
| --------------------------------------- | -------------------------------------------- | ------------------------------------- |
| **Isolation**                     | Containers have their own network namespace  | Containers share host's network stack |
| **Port conflicts**                | No conflicts (containers use internal ports) | May conflict with host services       |
| **Inter-container communication** | Via service names (DNS resolution)           | Via localhost and exposed ports       |
| **Security**                      | Better isolation                             | Less secure                           |

**In this project**: A dedicated Docker bridge network (`inception_net`) is used. Services
communicate using their service names as hostnames (e.g., WordPress connects to `mariadb`
and `redis` by name). Only specific ports are published to the host: NGINX (443), FTP (21,
21100-21110), cAdvisor (8000), and Static (3031). `network: host` and `--link` are not used.

#### Docker Volumes vs Bind Mounts

| Aspect                | Docker Volumes           | Bind Mounts              |
| --------------------- | ------------------------ | ------------------------ |
| **Management**  | Managed by Docker        | Direct host path         |
| **Portability** | More portable            | Tied to host filesystem  |
| **Performance** | Optimized for containers | Direct filesystem access |
| **Backup**      | Via Docker commands      | Standard file tools      |

**In this project**: Named volumes with the `local` driver and bind mount options are used:

- `db_data` → `/home/makarkao/data/db_data` (MariaDB database files)
- `wp_data` → `/home/makarkao/data/wp_data` (WordPress files)

This approach combines Docker's named volume management with direct access to the data on
the host filesystem under `/home/makarkao/data/`, as required by the 42 subject.

---

## Available Services

| Service   | Container | Port(s)         | Description                                    |
| --------- | --------- | --------------- | ---------------------------------------------- |
| NGINX     | nginx     | 443             | TLS reverse proxy, sole entry point            |
| WordPress | wordpress | 9000 (internal) | PHP-FPM WordPress application                  |
| MariaDB   | mariadb   | 3306 (internal) | MySQL-compatible database                      |
| Redis     | redis     | 6379 (internal) | Object cache for WordPress                     |
| Adminer   | adminer   | 9000 (internal) | Database admin panel (via NGINX `/adminer/`)   |
| FTP       | ftp       | 21, 21100-21110 | File transfer for WordPress files              |
| cAdvisor  | cadvisor  | 8000            | Container monitoring dashboard                 |
| Static    | static    | 3031            | Simple HTML/CSS resume site                    |

---

## Makefile Targets

| Target                   | Description                                                    |
| ------------------------ | -------------------------------------------------------------- |
| `make` or `make all` | Build images and start all containers                          |
| `make build`           | Build all Docker images                                        |
| `make up`              | Create data directories and start containers                   |
| `make down`            | Stop and remove containers (data preserved)                    |
| `make stop`            | Stop containers without removing them                          |
| `make start`           | Start previously stopped containers                            |
| `make clean`           | Stop containers and clear data directory contents              |
| `make fclean`          | Full cleanup: remove volumes, containers, data, and prune all images |

---

## Troubleshooting

### Website not accessible

1. Verify the domain resolves correctly:

   ```bash
   ping makarkao.42.fr
   ```

   If it fails, add to `/etc/hosts`:

   ```
   127.0.0.1 makarkao.42.fr
   ```
2. Check if containers are running:

   ```bash
   docker compose -f srcs/docker-compose.yml ps
   ```

### Database connection errors

1. Check MariaDB logs:

   ```bash
   docker compose -f srcs/docker-compose.yml logs mariadb
   ```
2. Verify secrets files exist in `secrets/` and contain valid passwords.

### SSL certificate warnings

This is expected behavior. The project uses a self-signed certificate generated at
image build time. Accept the security exception in your browser to proceed.

### Permission issues with data directories

```bash
sudo chown -R $USER:$USER /home/makarkao/data
```

# User Documentation

This guide explains how to use the Inception project stack as an end user or administrator.
No deep Docker knowledge is required—just follow the step-by-step instructions.

---

## Overview of the Stack

The Inception stack provides a complete web hosting environment with the following services:

| Service               | What It Does                                                                 |
| --------------------- | ---------------------------------------------------------------------------- |
| **WordPress**   | A content management system (CMS) for creating and managing your website     |
| **MariaDB**     | Stores all WordPress content (posts, pages, users, settings)                 |
| **NGINX**       | Reverse proxy that securely serves the website over HTTPS (TLSv1.2/TLSv1.3)  |
| **Redis**       | Speeds up WordPress by caching frequently accessed data in memory            |
| **Adminer**     | A web-based tool to view and manage the database (accessible via NGINX)      |
| **FTP**         | Allows file uploads/downloads to the WordPress directory using an FTP client |
| **cAdvisor**    | Shows real-time container performance and resource usage statistics          |
| **Static Site** | A simple personal resume page (HTML/CSS, served independently)               |

All services work together automatically once the stack is started.

---

## Starting and Stopping the Project

### Prerequisites

Before starting, ensure:

1. You are on a machine with **Docker** and **Docker Compose** (V2) installed
2. You have terminal access to the project directory
3. The password files exist in the `secrets/` folder (see [Managing Credentials](#locating-and-managing-credentials))
4. The domain `makarkao.42.fr` resolves to your machine's IP. If not, add it:
   ```bash
   echo "127.0.0.1 makarkao.42.fr" | sudo tee -a /etc/hosts
   ```

### Starting the Stack

1. Open a terminal and navigate to the project root folder:

   ```bash
   cd /path/to/inception
   ```
2. Run the following command to build and start all services:

   ```bash
   make
   ```
3. Wait for the build process to complete (this may take a few minutes on first run).
4. Once complete, all services will be running in the background.

### Stopping the Stack

To stop and remove all containers without losing data:

```bash
make down
```

To temporarily pause services (faster restart later):

```bash
make stop
```

To resume paused services:

```bash
make start
```

### Cleaning Up

To stop containers and clear data directory contents:

```bash
make clean
```

To perform a full cleanup (remove all volumes, containers, data, and prune images):

```bash
make fclean
```

> **Warning**: `make fclean` will delete all persistent data (WordPress files and database).

---

## Accessing the Website and Administration Panel

### Main Website

Open your web browser and go to:

```
https://makarkao.42.fr
```

> **Note**: Your browser may show a security warning because the site uses a self-signed
> certificate. This is normal. Click "Advanced" and then "Proceed" (or similar) to continue.

### WordPress Admin Panel

To manage your WordPress site (create posts, change settings, install plugins):

1. Go to:

   ```
   https://makarkao.42.fr/wp-admin
   ```
2. Log in with the administrator credentials (see [Managing Credentials](#locating-and-managing-credentials)).

### Adminer (Database Admin)

To view or manage the database directly:

1. Go to:

   ```
   https://makarkao.42.fr/adminer/
   ```
2. Log in with:

   - **System**: MySQL
   - **Server**: `mariadb`
   - **Username**: the database user defined in `srcs/.env` (e.g. `wp_userr`)
   - **Password**: contents of `secrets/db_password.txt`
   - **Database**: `wordpress`

### Container Monitoring (cAdvisor)

To view real-time performance statistics for all containers:

```
http://localhost:8000
```

### Static Resume Site

To view the static HTML resume page:

```
http://localhost:3031
```

---

## Locating and Managing Credentials

### Where Credentials Are Stored

Sensitive passwords are stored in the `secrets/` directory at the project root.
These files are **not committed to Git** (they are listed in `.gitignore`):

```
secrets/
├── db_password.txt         # Database user password
├── db_root_password.txt    # Database root password
├── ftp_password.txt        # FTP server password
├── wp_admin_password.txt   # WordPress admin password
└── wp_user_password.txt    # WordPress editor user password
```

Non-sensitive configuration (usernames, domain, site title, etc.) is stored in `srcs/.env`:

| Variable                   | Example Value                  | Description                              |
| -------------------------- | ------------------------------ | ---------------------------------------- |
| `DOMAIN_NAME`            | `makarkao.42.fr`             | Domain name for the site                 |
| `LOGIN`                  | `makarkao`                   | Host username (used for data paths)      |
| `MARIADB_DATABASE`       | `wordpress`                  | Database name                            |
| `MARIADB_USER`           | `wp_userr`                   | Database username                        |
| `MARIADB_PASSWORD_FILE`  | `/run/secrets/db_password`   | Path to DB user password secret          |
| `MARIADB_ROOT_PASSWORD_FILE` | `/run/secrets/db_root_password` | Path to DB root password secret     |
| `WORDPRESS_DB_HOST`      | `mariadb`                    | Hostname of the database service         |
| `WP_SITE_TITLE`          | `inception`                  | WordPress site title                     |
| `WP_SITE_URL`            | `https://makarkao.42.fr`     | Full URL of the WordPress site           |
| `WP_ADMIN_USER`          | `wpd_makarkao`               | WordPress admin username                 |
| `WP_ADMIN_EMAIL`         | `wpd_makarkao@42.fr`         | WordPress admin email                    |
| `WP_ADMIN_PASSWORD_FILE` | `/run/secrets/wp_admin_password` | Path to WP admin password secret    |
| `WP_USER`                | `ed_makarkao`                | WordPress editor username                |
| `WP_USER_EMAIL`          | `ed_makarkao@42.fr`          | WordPress editor email                   |
| `WP_USER_PASSWORD_FILE`  | `/run/secrets/wp_user_password` | Path to WP editor password secret    |
| `FTP_USER`               | `ftpmakarkao`                | FTP username                             |
| `FTP_PASS_FILE`          | `/run/secrets/ftp_password`  | Path to FTP password secret              |

### Default Users

| Account          | Username         | Password Location                 |
| ---------------- | ---------------- | --------------------------------- |
| WordPress Admin  | `wpd_makarkao` | `secrets/wp_admin_password.txt` |
| WordPress Editor | `ed_makarkao`  | `secrets/wp_user_password.txt`  |
| Database User    | `wp_userr`     | `secrets/db_password.txt`       |
| Database Root    | `root`         | `secrets/db_root_password.txt`  |
| FTP User         | `ftpmakarkao`  | `secrets/ftp_password.txt`      |

### Changing Passwords

To change a password:

1. Stop the stack:

   ```bash
   make down
   ```
2. Edit the appropriate file in `secrets/`:

   ```bash
   nano secrets/wp_admin_password.txt
   ```
3. For database passwords, you will need to perform a full clean and restart:

   ```bash
   make fclean
   make
   ```

> **Warning**: Changing database passwords after initial setup requires recreating
> the database. Back up your data first.

---

## Checking That Services Are Running Correctly

### Quick Browser Check

1. Visit `https://makarkao.42.fr` — you should see the WordPress site
2. Visit `https://makarkao.42.fr/wp-admin` — you should see the WordPress login page
3. Visit `https://makarkao.42.fr/adminer/` — you should see the Adminer login form
4. Visit `http://localhost:8000` — you should see the cAdvisor dashboard
5. Visit `http://localhost:3031` — you should see the static resume page

### Command-Line Check

To see the status of all containers:

```bash
docker compose -f srcs/docker-compose.yml ps
```

**Healthy output example:**

```
NAME        IMAGE               STATUS          PORTS
adminer     adminer:inception   Up 2 minutes
cadvisor    cadvisor:inception  Up 2 minutes    0.0.0.0:8000->8080/tcp
ftp         ftp:inception       Up 2 minutes    0.0.0.0:21->21/tcp, 0.0.0.0:21100-21110->21100-21110/tcp
mariadb     mariadb:inception   Up 2 minutes
nginx       nginx:inception     Up 2 minutes    0.0.0.0:443->443/tcp
redis       redis:inception     Up 2 minutes
static      static:inception    Up 2 minutes    0.0.0.0:3031->80/tcp
wordpress   wordpress:inception Up 2 minutes
```

All containers should show `Up` in the STATUS column.

### Checking Logs

If something isn't working, check the logs:

```bash
# All containers
docker compose -f srcs/docker-compose.yml logs

# Specific container (e.g., wordpress)
docker compose -f srcs/docker-compose.yml logs wordpress
```

### Common Issues and Solutions

| Problem                                  | Possible Cause                      | Solution                                                                   |
| ---------------------------------------- | ----------------------------------- | -------------------------------------------------------------------------- |
| "This site can't be reached"             | Containers not running              | Run `make` to start                                                      |
| "This site can't be reached"             | Domain not in hosts file            | Add `127.0.0.1 makarkao.42.fr` to `/etc/hosts`                         |
| Certificate warning                      | Self-signed certificate             | Click through the warning (this is expected)                               |
| "Error establishing database connection" | MariaDB not ready or wrong password | Check logs with `docker compose -f srcs/docker-compose.yml logs mariadb` |
| WordPress shows blank page               | PHP error                           | Check `docker compose -f srcs/docker-compose.yml logs wordpress`         |
| FTP connection refused                   | Container not running or wrong port | Verify with `docker compose -f srcs/docker-compose.yml ps`               |

---

## FTP Access

To connect to the FTP server for file management:

- **Host**: `makarkao.42.fr` (or `localhost`)
- **Port**: `21`
- **Username**: `ftpmakarkao` (as defined in `srcs/.env`)
- **Password**: contents of `secrets/ftp_password.txt`
- **Mode**: Passive (ports 21100–21110)

Use an FTP client like FileZilla to connect. The FTP root is the WordPress installation
directory (`/var/www/html`), so you can upload themes, plugins, or media files directly.

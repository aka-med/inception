COMPOSE_FILE := ./srcs/docker-compose.yml
DATA_DIR := /home/makarkao/data
WORDPRESS_DATA := $(DATA_DIR)/wp_data
MARIADB_DATA := $(DATA_DIR)/db_data

all: build up

build:
	docker compose -f $(COMPOSE_FILE) build

up: create_dirs
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

stop : 
	docker compose -f $(COMPOSE_FILE) stop

start : 
	docker compose -f $(COMPOSE_FILE) start

create_dirs:
	@mkdir -p $(WORDPRESS_DATA)
	@mkdir -p $(MARIADB_DATA)

clean: down
	@sudo rm -rf $(WORDPRESS_DATA)/*
	@sudo rm -rf $(MARIADB_DATA)/*

fclean:
	@docker compose -f $(COMPOSE_FILE) down -v
	@sudo rm -rf $(DATA_DIR)
	@docker system prune -af
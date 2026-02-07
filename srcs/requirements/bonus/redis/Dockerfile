FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    redis-server \
 && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf && \
    sed -i 's/^protected-mode .*/protected-mode no/' /etc/redis/redis.conf && \
    sed -i 's/^daemonize .*/daemonize no/' /etc/redis/redis.conf && \
    sed -i 's/^# *maxmemory .*/maxmemory 64mb/' /etc/redis/redis.conf && \
    sed -i 's/^# *maxmemory-policy .*/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    
CMD ["redis-server", "/etc/redis/redis.conf"]
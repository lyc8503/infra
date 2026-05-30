FROM debian:stable-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    smokeping fping nginx fcgiwrap spawn-fcgi \
    && rm -rf /var/lib/apt/lists/*

COPY nginx-default.conf /etc/nginx/sites-available/default
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /run/fcgiwrap /var/lib/smokeping && \
    chown -R www-data:www-data /var/lib/smokeping

ENTRYPOINT ["/entrypoint.sh"]

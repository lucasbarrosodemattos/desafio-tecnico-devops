FROM nginx:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl libcap2-bin \
    && setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx \
    && rm -rf /var/lib/apt/lists/*

COPY src/ /usr/share/nginx/html/
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY docker/entrypoint/99-inject-app-version.sh /docker-entrypoint.d/99-inject-app-version.sh

RUN chmod +x /docker-entrypoint.d/99-inject-app-version.sh \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx \
        /docker-entrypoint.d \
        /etc/nginx/conf.d \
        /usr/share/nginx/html \
        /var/cache/nginx \
        /var/log/nginx \
        /var/run/nginx.pid

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl --fail --silent --show-error http://localhost/health || exit 1
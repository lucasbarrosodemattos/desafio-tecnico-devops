FROM nginx:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

COPY src/ /usr/share/nginx/html/
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY docker/entrypoint/99-inject-app-version.sh /docker-entrypoint.d/99-inject-app-version.sh

RUN chmod +x /docker-entrypoint.d/99-inject-app-version.sh

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl --fail --silent --show-error http://localhost/health || exit 1